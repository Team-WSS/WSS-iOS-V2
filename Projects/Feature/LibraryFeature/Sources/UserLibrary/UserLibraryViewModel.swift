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
        /// 첫 페이지 로드 실패 여부 — View가 "서재 비어있음"과 "로드 실패"를 구분해 그리기 위한 상태.
        /// (더보기 실패는 기존 목록을 유지하므로 토스트만 띄우고 이 값은 건드리지 않는다.)
        var loadFailed = false
        /// 인증 만료(세션 죽음) 감지 시 상위에 로그인 라우팅을 요청하는 신호.
        /// View가 `onChange`로 받은 뒤 `.consumeAuthenticationRequired`로 되돌린다 —
        /// 이 화면은 push라 보통 dismiss되지만, 로그인 화면에서 되돌아와 정렬을 바꾸면 VM이 그대로 살아 있다.
        var requiresAuthentication = false
        /// 표시할 토스트(의미값). 표현(문구·스타일) 매핑은 View가 한다(얇은 ViewModel).
        /// 첫 페이지 로드 실패는 전면 실패 뷰(`loadFailed`)가 표현하므로 여기 없다.
        var presentedToast: UserLibraryToast?
    }

    /// 사용자에게 표시할 토스트의 **의미값**. 카피·표현은 View가 결정한다.
    enum UserLibraryToast: Equatable {
        case loadMoreFailed
    }

    // MARK: - Action

    enum Action {
        case load
        case retry
        case loadMore
        case selectSortType(LibrarySortType)
        case dismissToast
        case consumeAuthenticationRequired
    }

    // MARK: - Output

    private(set) var state: State

    // MARK: - Property

    // 1회 가드 플래그는 실패 고착을 막기 위해 **성공 시에만** 소진한다(내 서재와 동일).
    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    /// 서버 발급 커서 — 다음 페이지 요청에 그대로 왕복한다. View가 볼 값이 아니라 State 밖.
    @ObservationIgnored private var nextCursor: String?
    @ObservationIgnored private var hasNext = true
    /// 정렬 변경으로 목록을 갈아엎을 때 증가 — 이전 로드의 늦은 결과·defer가 새 로드를 덮지 않게 가드한다.
    @ObservationIgnored private var loadGeneration = 0

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
        case .dismissToast:
            state.presentedToast = nil
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
        let generation = loadGeneration
        loadTask = Task { await loadPage(cursor: cursor, generation: generation) }
    }

    /// 정렬 선택(정렬 시트). 같은 값 재선택은 무시한다.
    func selectSortType(_ sortType: LibrarySortType) {
        guard state.filter.sortType != sortType else { return }
        state.filter.setSortType(sortType)
        reloadFromScratch()
    }

    /// 목록을 처음부터 다시 로드한다(첫 로드·재시도·정렬 변경 공통).
    /// 진행 중이던 로드는 세대(generation)를 올려 무효화한다 — 늦게 도착한 이전 결과가 새 목록을 덮지 않는다.
    func reloadFromScratch() {
        loadGeneration += 1
        loadTask?.cancel()
        nextCursor = nil
        hasNext = true
        state.novels = []
        // ⚠️ `totalCount`는 비우지 않는다 — 이 화면이 바꿀 수 있는 건 정렬뿐이라 개수가 달라지지 않는데,
        // 0으로 떨어뜨리면 로딩 동안 헤더의 "n개"가 "0개"로 깜빡였다 돌아온다.
        // (내 서재는 필터로 개수가 실제로 바뀌므로 거기선 비우는 게 맞다.)
        state.isLoading = true
        state.isLoadingMore = false
        state.loadFailed = false
        let generation = loadGeneration
        loadTask = Task { await loadPage(cursor: nil, generation: generation) }
    }
}

// MARK: - UseCase Handling

private extension UserLibraryViewModel {

    /// 타유저 서재 페이지 로드. `cursor == nil`이면 첫 페이지(목록 교체), 아니면 다음 페이지(append).
    func loadPage(cursor: String?, generation: Int) async {
        defer {
            if generation == loadGeneration {
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
            guard generation == loadGeneration, !Task.isCancelled else { return }
            if cursor == nil {
                state.novels = page.items
                hasLoaded = true
            } else {
                state.novels.append(contentsOf: page.items)
            }
            state.totalCount = totalCount
            nextCursor = page.nextCursor
            hasNext = page.hasNext
            state.loadFailed = false
        } catch {
            guard generation == loadGeneration, !Task.isCancelled else { return }
            // 인증 만료는 실패 뷰/토스트 대신 로그인 유도로 일원화 — 실패 플래그보다 **먼저** 거른다(정본과 대칭).
            // 세션이 죽은 상태라 실패 뷰의 재시도는 같은 에러로 되돌아올 뿐이고, 문구도 원인을 잘못 말한다.
            // 화면을 치우는 건 `onAuthenticationRequired`를 받은 App의 책임이다.
            if routeToLoginIfAuthenticationRequired(error) { return }
            if cursor == nil {
                // 첫 페이지 실패는 전면 실패 뷰가 표현한다 — 토스트까지 띄우면 에러 시그널이 이중화된다.
                state.loadFailed = true
                logger?.error("UserLibrary 실패(load): \(String(describing: error))")
            } else {
                presentError(error, as: .loadMoreFailed)
            }
        }
    }
}

// MARK: - Error Mapping

private extension UserLibraryViewModel {

    /// Repository 에러를 발생 맥락의 의미 토스트로 변환한다. 원인은 로그로 남긴다.
    func presentError(_ error: Error, as presented: UserLibraryToast) {
        if routeToLoginIfAuthenticationRequired(error) { return }
        logger?.error("UserLibrary 실패(\(presented)): \(String(describing: error))")
        if state.presentedToast != nil { return }
        state.presentedToast = presented
    }

    /// 인증 만료(`authenticationRequired`)면 로그인 라우팅 신호를 세우고 true 반환.
    /// 세션이 죽은 상황이라 개별 실패 토스트 대신 로그인 유도로 일원화한다.
    func routeToLoginIfAuthenticationRequired(_ error: Error) -> Bool {
        guard (error as? RepositoryError) == .authenticationRequired else { return false }
        state.requiresAuthentication = true
        return true
    }
}
