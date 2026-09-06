//
//  UserLibraryViewModel.swift
//  LibraryFeature
//
//  Created by YunhakLee on 7/30/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import NovelDomain
import Logger

@MainActor
@Observable
final class UserLibraryViewModel {

    // MARK: - State

    struct State {
        var novels: [LibraryNovel] = []
        /// 상대 서재의 전체 작품 수 (헤더 "n개" 표기).
        var totalCount = 0
        /// 타유저 서재는 정렬만 조절한다 — 필터 UI가 없다(디자인).
        var filter = LibraryFilter()
        /// 초기값 true — onAppear의 `.load`보다 첫 body 평가가 먼저라, false로 시작하면
        /// 로드 시작 전 한 프레임 동안 빈 상태/실패 뷰가 스친다. (내 서재와 동일한 이유)
        var isLoading = true
        /// 다음 페이지 로드 중 (하단 스피너용). 첫 페이지 로드는 `isLoading`.
        var isLoadingMore = false
        /// 목록 로드 실패 여부(첫 페이지·더보기·갱신 **공통**) — 목록 자리를 전면 실패 뷰로 대체할지 가른다.
        /// ⚠️ 더보기 실패를 여기서 빼고 토스트로 가르지 말 것 — 토스트는 사라지면 재시도 경로가 없어
        /// 하단에서 페이지네이션이 멈춘 채 갇힌다(#195 실측). 규칙 정본: Feature CLAUDE.md "로드 실패 표현 계약".
        var loadFailed: RepositoryError?
        /// 인증 만료(세션 죽음) 감지 시 상위에 로그인 라우팅을 요청하는 신호.
        /// View가 `onChange`로 받은 뒤 `.consumeAuthenticationRequired`로 되돌린다 —
        /// 이 화면은 push라 보통 dismiss되지만, 로그인 화면에서 되돌아와 정렬을 바꾸면 VM이 그대로 살아 있다.
        var requiresAuthentication = false
    }

    // MARK: - Action

    enum Action {
        case load
        case retry
        case loadMore
        case selectSortType(LibrarySortType)
        case consumeAuthenticationRequired
    }

    // MARK: - Output

    private(set) var state: State

    // MARK: - Property

    // 1회 가드 플래그는 실패 고착을 막기 위해 **성공 시에만** 소진한다.
    // ⚠️ 내 서재는 이 가드를 걷어내고 재진입마다 갱신하지만(`hasLoadedContent`), 이 화면은 **push라
    // 재진입마다 화면이 새로 서므로 갱신 자체가 없어** 1회 가드가 그대로 맞다. 내 서재를 따라가지 말 것.
    @ObservationIgnored private var hasLoaded = false
    /// 진행 중인 목록 로드. ⚠️ **로드는 항상 이 한 슬롯에만 산다** — "무효해진 로드 == 취소된 로드"라는
    /// 등식이 여기서 나오고, 그 등식이 세대 카운터를 대신한다(`loadPage` 주석, 내 서재와 동일).
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    /// 서버 발급 커서 — 다음 페이지 요청에 그대로 왕복한다. View가 볼 값이 아니라 State 밖.
    @ObservationIgnored private var nextCursor: String?
    @ObservationIgnored private var hasNext = true

    // MARK: - Dependency

    /// 조회 대상 사용자 — 화면 전환 시 호출자가 주입한다.
    private let userID: UserID
    private let logger: Logger?

    // NovelDomain
    private let loadUserLibraryUseCase: LoadUserLibraryUseCase

    // MARK: - Init

    init(
        userID: UserID,
        loadUserLibraryUseCase: LoadUserLibraryUseCase,
        logger: Logger? = nil
    ) {
        self.userID = userID
        self.loadUserLibraryUseCase = loadUserLibraryUseCase
        self.logger = logger
        self.state = State()
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .load:
            load()
        case .retry:
            retry()
        case .loadMore:
            loadMore()
        case .selectSortType(let sortType):
            selectSortType(sortType)
        case .consumeAuthenticationRequired:
            state.requiresAuthentication = false
        }
    }
}

// MARK: - Action Handling

private extension UserLibraryViewModel {

    /// 진입 시 첫 페이지 로드. onAppear는 재진입마다 불리므로 성공 후에는 다시 로드하지 않되,
    /// 실패는 가드를 소진하지 않아 재진입 시 재시도가 열려 있다.
    func load() {
        guard !hasLoaded, loadTask == nil else { return }
        reloadFromScratch()
    }

    /// 전면 실패 뷰의 재시도.
    func retry() {
        guard loadTask == nil else { return }
        reloadFromScratch()
    }

    /// 다음 페이지 로드. 커서는 직전 응답의 `nextCursor`를 그대로 왕복한다.
    func loadMore() {
        guard hasNext,
              loadTask == nil,
              !state.isLoading,
              let cursor = nextCursor else { return }
        state.isLoadingMore = true
        loadTask = Task { await loadPage(cursor: cursor) }
    }

    /// 정렬 선택(정렬 시트). 같은 값 재선택은 무시한다.
    func selectSortType(_ sortType: LibrarySortType) {
        guard state.filter.sortType != sortType else { return }
        state.filter.setSortType(sortType)
        reloadFromScratch()
    }

    /// 목록을 처음부터 다시 로드한다(첫 로드·재시도·정렬 변경 공통).
    /// 진행 중이던 로드는 **취소**해 무효화한다 — 늦게 도착한 이전 결과가 새 목록을 덮지 않는다.
    ///
    /// ⚠️ 목록을 갈아엎는 경로는 **전부 여기를 거쳐야 한다**(이 화면은 정렬 변경뿐이라 실제로 그렇다).
    /// 그리고 **취소는 언제나 재대입과 짝이어야 한다** — 취소만 하고 새 Task를 넣지 않으면 슬롯이
    /// non-nil로 굳어 이후 로드가 전부 막힌다(내 서재와 공유하는 조건).
    func reloadFromScratch() {
        loadTask?.cancel()
        nextCursor = nil
        hasNext = true
        state.novels = []
        // ⚠️ `totalCount`는 비우지 않는다 — 이 화면이 바꿀 수 있는 건 정렬뿐이라 개수가 달라지지 않는데,
        // 0으로 떨어뜨리면 로딩 동안 헤더의 "n개"가 "0개"로 깜빡였다 돌아온다.
        // (내 서재는 필터로 개수가 실제로 바뀌므로 거기선 비우는 게 맞다.)
        state.isLoading = true
        state.isLoadingMore = false
        state.loadFailed = nil
        loadTask = Task { await loadPage(cursor: nil) }
    }
}

// MARK: - UseCase Handling

private extension UserLibraryViewModel {

    /// 타유저 서재 페이지 로드. `cursor == nil`이면 첫 페이지(목록 교체), 아니면 다음 페이지(append).
    ///
    /// **무효해진 로드 == 취소된 로드**다 — 목록을 갈아엎는 경로가 전부 `reloadFromScratch()`를 거치고
    /// 거기서 이전 로드를 반드시 취소하므로, 세대 카운터 없이 `Task.isCancelled`만으로 "늦게 도착한
    /// 이전 결과"를 걸러낼 수 있다(내 서재와 동일한 근거).
    func loadPage(cursor: String?) async {
        defer {
            // 취소된 로드는 **아무것도 정리하지 않는다** — 정리하면 자기를 밀어낸 새 로드의
            // `loadTask`와 로딩 표시를 지운다. (defer 안에서는 `return`할 수 없어 `if`로 감싼다.)
            if !Task.isCancelled {
                loadTask = nil
                state.isLoading = false
                state.isLoadingMore = false
            }
        }
        do {
            let (page, totalCount) = try await loadUserLibraryUseCase.execute(
                id: userID,
                filter: state.filter,
                cursor: cursor
            )
            guard !Task.isCancelled else { return }
            if cursor == nil {
                state.novels = page.items
                hasLoaded = true
            } else {
                state.novels.append(contentsOf: page.items)
            }
            state.totalCount = totalCount
            nextCursor = page.nextCursor
            hasNext = page.hasNext
            state.loadFailed = nil
        } catch {
            guard !Task.isCancelled else { return }
            // 인증 만료는 실패 뷰/토스트 대신 로그인 유도로 일원화 — 실패 플래그보다 **먼저** 거른다(정본과 대칭).
            // 세션이 죽은 상태라 실패 뷰의 재시도는 같은 에러로 되돌아올 뿐이고, 문구도 원인을 잘못 말한다.
            // 화면을 치우는 건 `onAuthenticationRequired`를 받은 App의 책임이다.
            if routeToLoginIfAuthenticationRequired(error) { return }

            // 첫 페이지든 더보기든 **전면 실패 뷰**가 표현한다 — 토스트는 사라지면 재시도할 방법이 없어
            // 하단에서 더보기가 실패하면 페이지네이션이 멈춘 채 갇힌다(내 서재에서 실제로 겪었다).
            // 규칙 정본: Feature CLAUDE.md "로드 실패 표현 계약".
            state.loadFailed = (error as? RepositoryError) ?? .unknown
            logger?.error("UserLibrary 목록 로드 실패(\(cursor == nil ? "첫 페이지" : "더보기")): \(String(describing: error))")
        }
    }
}

// MARK: - Error Mapping

private extension UserLibraryViewModel {

    /// 인증 만료(`authenticationRequired`)면 로그인 라우팅 신호를 세우고 true 반환.
    /// 세션이 죽은 상황이라 실패 뷰 대신 로그인 유도로 일원화한다(이 화면엔 토스트가 없다).
    func routeToLoginIfAuthenticationRequired(_ error: Error) -> Bool {
        guard (error as? RepositoryError) == .authenticationRequired else { return false }
        state.requiresAuthentication = true
        return true
    }
}
