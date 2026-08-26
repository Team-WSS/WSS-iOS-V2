//
//  CollectionMyLibrarySelectViewModel.swift
//  CollectionFeature
//
//  Created by Guryss on 8/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import CollectionDomain
import NovelDomain
import Logger

/// 컬렉션 "작품 추가" 화면(`CollectionSearchNovelView`)의 "서재에서 추가"로 진입하는 화면 —
/// 사용자의 서재를 조회하며 다중 선택한 결과를 `CollectionSearchNovelView`로 되돌려준다.
/// `ReadingPeriodSheet`처럼 이 모듈 내부에서만 push되는 로컬 화면이라 Factory로 노출하지 않는다.
///
/// 선택 상태 관리(`selectedNovels`/`toggleNovel`/`isAtCapacity`/`confirm`)는
/// `CollectionSearchNovelViewModel`과 동일한 shape — 검색으로 이미 고른 작품을 `initialSelection`으로
/// 시드받아 그 위에서 계속 담기 때문에, 확정 시 `state.selectedNovels`가 이미 검색+서재 병합본이다.
///
/// 데이터 로드는 `CollectionSearchNovelViewModel`의 정수 `page` 방식이 아니라, `LoadMyLibraryUseCase`가
/// 커서 기반이라 `LibraryFeature.LibraryViewModel`의 "커서 + generation 카운터" 패턴을 그대로 이식했다
/// (`LibraryFeature/CLAUDE.md` 참고 — 진행 중이던 로드의 늦은 응답이 새 목록을 덮지 않게 가드).
@MainActor
@Observable
final class CollectionMyLibrarySelectViewModel {

    // MARK: - State

    struct State {
        var novels: [LibraryNovel] = []
        /// 검색(`CollectionSearchNovelView`)에서 이미 고른 것 + 이 화면에서 고른 것이 합쳐진 최종 선택.
        /// **가장 최근에 고른 작품이 배열 맨 앞**(`CollectionSearchNovelViewModel`과 동일 계약) — 이
        /// 화면에서 고른 작품은 검색에서 고른 것보다 시간상 나중이므로 항상 그 앞에 꽂힌다.
        var selectedNovels: [CollectionNovel]
        /// 초기값 true — onAppear의 `.load`보다 첫 body 평가가 먼저라, false로 시작하면 로드 시작 전
        /// 한 프레임 동안 빈 상태가 스친다(`LibraryViewModel`과 동일 이유).
        var isLoading = true
        var isLoadingMore = false
        var loadFailed = false
        var isConfirmed = false
        var requiresAuthentication = false
        var presentedToast: MyLibrarySelectToast?
    }

    enum MyLibrarySelectToast: Equatable {
        case loadMoreFailed
        /// 정원(100개) 도달 후 더 담으려 할 때. 토스트 문구는 `WSSToastType.selectionOverLimit`의
        /// 범용 문구를 임시로 쓴다 — 기획팀 확정 문구 전달 예정(2026-08-24).
        case selectionLimitReached
    }

    // MARK: - Derived

    var selectedNovelIDs: Set<NovelID> { Set(state.selectedNovels.map(\.id)) }
    var isAtCapacity: Bool { state.selectedNovels.count >= CollectionDraft.maxNovelCount }

    // MARK: - Action

    enum Action {
        case load
        case retry
        case loadMore
        case toggleNovel(LibraryNovel)
        case confirm
        case dismissToast
    }

    // MARK: - Output

    private(set) var state: State

    // MARK: - Property

    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    /// 서버 발급 커서 — 다음 페이지 요청에 그대로 왕복한다. View가 볼 값이 아니라 State 밖.
    @ObservationIgnored private var nextCursor: String?
    @ObservationIgnored private var hasNext = true
    /// 재시도 등으로 목록을 갈아엎을 때 증가 — 이전 로드의 늦은 결과가 새 로드를 덮지 않게 가드한다.
    @ObservationIgnored private var loadGeneration = 0

    // MARK: - Dependency

    private let logger: Logger?

    // NovelDomain
    private let loadMyLibraryUseCase: LoadMyLibraryUseCase

    // MARK: - Init

    /// - Parameters:
    ///   - initialSelection: `CollectionSearchNovelView`가 넘기는, 검색으로 이미 고른 작품 스냅샷.
    ///     이 화면에서 추가로 고르는 작품과 같은 배열에서 계속 이어 담기므로, 확정 시 별도로 합칠
    ///     필요 없이 `state.selectedNovels` 자체가 최종 병합본이다.
    init(
        initialSelection: [CollectionNovel],
        loadMyLibraryUseCase: LoadMyLibraryUseCase,
        logger: Logger? = nil
    ) {
        self.loadMyLibraryUseCase = loadMyLibraryUseCase
        self.logger = logger
        self.state = State(selectedNovels: initialSelection)
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
        case .toggleNovel(let novel):
            toggleNovel(novel)
        case .confirm:
            state.isConfirmed = true
        case .dismissToast:
            state.presentedToast = nil
        }
    }
}

// MARK: - Action Handling

private extension CollectionMyLibrarySelectViewModel {

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

    /// 선택 토글. 이미 골랐으면 해제, 아니면 담는다 — 정원(100개)이 차면 더 담지 않고 토스트로 알린다
    /// (`CollectionSearchNovelViewModel`과 동일 패턴).
    ///
    /// `LibraryNovel`엔 author 필드가 아예 없고, `CollectionNovel.author`는 CollectionFeature
    /// 어디서도 실제로 표시되지 않는다(확인 완료) — 빈 문자열로 채우는 게 안전하고 의도적인 결정이다.
    func toggleNovel(_ novel: LibraryNovel) {
        if let index = state.selectedNovels.firstIndex(where: { $0.id == novel.id }) {
            state.selectedNovels.remove(at: index)
        } else {
            guard !isAtCapacity else {
                if state.presentedToast == nil { state.presentedToast = .selectionLimitReached }
                return
            }
            state.selectedNovels.insert(
                CollectionNovel(id: novel.id, title: novel.title, author: "", thumbnailImage: novel.thumbnailImage),
                at: 0
            )
        }
    }

    /// 목록을 처음부터 다시 로드한다(첫 로드·재시도 공통 — 이 화면엔 필터/정렬 UI가 없다).
    func reloadFromScratch() {
        loadGeneration += 1
        loadTask?.cancel()
        nextCursor = nil
        hasNext = true
        state.novels = []
        state.isLoading = true
        state.isLoadingMore = false
        state.loadFailed = false
        let generation = loadGeneration
        loadTask = Task { await loadPage(cursor: nil, generation: generation) }
    }
}

// MARK: - UseCase Handling

private extension CollectionMyLibrarySelectViewModel {

    /// 서재 페이지 로드. `cursor == nil`이면 첫 페이지(목록 교체), 아니면 다음 페이지(append).
    /// 필터 UI가 없는 순수 선택 화면이라 항상 기본값(전체) 필터로 조회한다.
    func loadPage(cursor: String?, generation: Int) async {
        defer {
            if generation == loadGeneration {
                loadTask = nil
                state.isLoading = false
                state.isLoadingMore = false
            }
        }
        do {
            let (page, _) = try await loadMyLibraryUseCase.execute(
                filter: MyLibraryFilter(),
                cursor: cursor,
                size: LibraryPageSizePolicy.pageSize
            )
            guard generation == loadGeneration, !Task.isCancelled else { return }
            if cursor == nil {
                state.novels = page.items
                hasLoaded = true
            } else {
                state.novels.append(contentsOf: page.items)
            }
            nextCursor = page.nextCursor
            hasNext = page.hasNext
            state.loadFailed = false
        } catch {
            guard generation == loadGeneration, !Task.isCancelled else { return }
            // 인증 만료는 실패 뷰/토스트 대신 로그인 유도로 일원화 — 실패 플래그보다 먼저 거른다.
            if routeToLoginIfAuthenticationRequired(error) { return }
            if cursor == nil {
                state.loadFailed = true
                logger?.error("CollectionMyLibrarySelect 실패(load): \(String(describing: error))")
            } else {
                presentError(error, as: .loadMoreFailed)
            }
        }
    }
}

// MARK: - Error Mapping

private extension CollectionMyLibrarySelectViewModel {

    func presentError(_ error: Error, as presented: MyLibrarySelectToast) {
        if routeToLoginIfAuthenticationRequired(error) { return }
        logger?.error("CollectionMyLibrarySelect 실패(\(presented)): \(String(describing: error))")
        if state.presentedToast != nil { return }
        state.presentedToast = presented
    }

    /// push 후 dismiss되는 화면(`CollectionSearchNovelViewModel`과 동일 위상, 탭 콘텐츠 아님)이라
    /// `LibraryViewModel`처럼 신호를 소진(`.consumeAuthenticationRequired`)할 필요 없이 1회성으로 충분하다.
    func routeToLoginIfAuthenticationRequired(_ error: Error) -> Bool {
        guard (error as? RepositoryError) == .authenticationRequired else { return false }
        state.requiresAuthentication = true
        return true
    }
}
