//
//  CollectionListViewModel.swift
//  CollectionFeature
//
//  Created by Guryss on 8/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import CollectionDomain
import Logger

/// "내 컬렉션"/"좋아요한 컬렉션"을 세그먼트 탭으로 전환. 마이페이지 "컬렉션 N개" 행에서 진입한다
/// (`UserPageFeature`가 콜백만 노출, 실제 화면 전환 배선은 App 몫 — 두 Feature는 서로 import 못 한다).
enum CollectionListTab: CaseIterable, Hashable {
    case mine
    case liked
}

@MainActor
@Observable
final class CollectionListViewModel {

    // MARK: - State

    struct State {
        var selectedTab: CollectionListTab = .mine
        var mine = TabContent()
        var liked = TabContent()
        var requiresAuthentication = false
        var presentedToast: CollectionListToast?
    }

    /// 탭 하나가 화면을 그리는 데 필요한 상태.
    struct TabContent {
        var items: [CollectionCard] = []
        var totalCount = 0
        /// 초기값 true — onAppear의 `.load`보다 첫 body 평가가 먼저라, false로 시작하면 로드 시작 전
        /// 한 프레임 빈 상태가 스친다(`CollectionMyLibrarySelectViewModel`과 동일 이유).
        var isLoading = true
        var isLoadingMore = false
        var loadFailed: RepositoryError?
    }

    enum CollectionListToast: Equatable {
        case loadMoreFailed
    }

    // MARK: - Action

    enum Action {
        case load
        case selectTab(CollectionListTab)
        /// 대상 탭을 명시로 받는다(`state.selectedTab` 암묵 참조 ❌) — 두 탭의 그리드/리스트를
        /// **동시에 마운트해두고 보이는 쪽만 바꾸는 구조**(아래 View 쪽 주석 참고)라, 안 보이는
        /// 탭의 셀도 onAppear가 fire될 수 있다. 그때 "현재 선택된 탭"으로 잘못 적용되지 않게 한다.
        case retry(CollectionListTab)
        case loadMore(CollectionListTab)
        /// "컬렉션 만들기"/`CollectionDetailView` 복귀 시(둘 다 App이 push) — 좋아요·삭제·생성으로
        /// 그 탭의 카드가 바뀌었을 수 있어 성공/취소 구분 없이 무조건 다시 로드한다. "컬렉션 만들기"는
        /// `.mine` 탭에서만 진입 가능해(그 탭에서만 버튼이 보임) 두 진입 경로 모두 대상 탭 하나로
        /// 충분히 표현된다 — 별도 액션으로 나눌 필요가 없다.
        case reloadAfterReturn(CollectionListTab)
        case dismissToast
    }

    // MARK: - Output

    private(set) var state = State()

    // MARK: - Property

    /// 탭별 커서+generation 부기(View가 안 보는 값) — 진행 중이던 로드의 늦은 응답이 새 목록을
    /// 덮지 않게 가드한다. `CollectionMyLibrarySelectViewModel`의 패턴을 탭 2개로 확장한 형태.
    private struct LoadBookkeeping {
        var nextCursor: String?
        var hasNext = true
        var hasLoaded = false
        var generation = 0
        var task: Task<Void, Never>?
    }
    @ObservationIgnored private var mineBookkeeping = LoadBookkeeping()
    @ObservationIgnored private var likedBookkeeping = LoadBookkeeping()

    /// 서버 권장 페이지 크기가 따로 없어(서재와 동일 상황) 화면이 직접 정한다.
    private static let pageSize = 20

    // MARK: - Dependency

    private let userID: UserID
    private let logger: Logger?

    // CollectionDomain
    private let loadCollectionsUseCase: LoadCollectionsUseCase
    private let loadLikedCollectionsUseCase: LoadLikedCollectionsUseCase

    // MARK: - Init

    init(
        userID: UserID,
        loadCollectionsUseCase: LoadCollectionsUseCase,
        loadLikedCollectionsUseCase: LoadLikedCollectionsUseCase,
        logger: Logger? = nil
    ) {
        self.userID = userID
        self.loadCollectionsUseCase = loadCollectionsUseCase
        self.loadLikedCollectionsUseCase = loadLikedCollectionsUseCase
        self.logger = logger
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .load:
            loadIfNeeded(state.selectedTab)
        case .selectTab(let tab):
            state.selectedTab = tab
            loadIfNeeded(tab)
        case .retry(let tab):
            retry(tab)
        case .loadMore(let tab):
            loadMore(tab)
        case .reloadAfterReturn(let tab):
            reload(tab)
            // 좋아요/삭제는 반대편 탭의 카드에도 영향을 줄 수 있다(예: 좋아요 토글은 "좋아요한
            // 컬렉션" 목록 자체를 바꾼다) — 지금 안 보이는 탭까지 당장 재요청하는 대신 hasLoaded만
            // 꺼서, 나중에 그 탭으로 전환하는 순간 loadIfNeeded가 자동으로 새로 불러오게 한다.
            invalidate(otherTab(of: tab))
        case .dismissToast:
            state.presentedToast = nil
        }
    }
}

// MARK: - Action Handling

private extension CollectionListViewModel {

    /// 탭 전환 시 그 탭을 아직 한 번도 안 불렀으면 첫 페이지를 로드한다(lazy 1회 로드 —
    /// 이미 봤던 탭을 다시 오가도 재요청하지 않는다).
    func loadIfNeeded(_ tab: CollectionListTab) {
        guard !bookkeeping(for: tab).hasLoaded, bookkeeping(for: tab).task == nil else { return }
        reload(tab)
    }

    /// 전면 실패 뷰의 재시도.
    func retry(_ tab: CollectionListTab) {
        guard bookkeeping(for: tab).task == nil else { return }
        reload(tab)
    }

    /// 진행 중인 로드는 건드리지 않고 `hasLoaded`만 꺼서 다음 `loadIfNeeded` 호출(탭 전환)이
    /// 그 탭을 다시 첫 페이지부터 불러오게 만든다 — 지금 화면에 없는 탭을 미리 당겨 로드하지 않는다.
    /// `generation`도 함께 올려, 이미 진행 중이던(무효화 전에 시작된) 로드가 뒤늦게 성공해도
    /// `loadPage`의 generation 가드에 걸려 `hasLoaded`를 다시 `true`로 되돌리지 못하게 막는다
    /// (안 그러면 무효화 의도가 무효화되고 다음 탭 진입 때 stale 데이터가 그대로 남을 수 있다).
    func invalidate(_ tab: CollectionListTab) {
        updateBookkeeping(for: tab) {
            $0.hasLoaded = false
            $0.generation += 1
        }
    }

    func otherTab(of tab: CollectionListTab) -> CollectionListTab {
        switch tab {
        case .mine: .liked
        case .liked: .mine
        }
    }

    /// 그 탭의 다음 페이지. 커서는 직전 응답의 `nextCursor`를 그대로 왕복한다.
    func loadMore(_ tab: CollectionListTab) {
        let book = bookkeeping(for: tab)
        guard book.hasNext, book.task == nil, !content(for: tab).isLoading,
              let cursor = book.nextCursor else { return }
        updateContent(for: tab) { $0.isLoadingMore = true }
        let generation = book.generation
        let task = Task { await loadPage(tab: tab, cursor: cursor, generation: generation) }
        updateBookkeeping(for: tab) { $0.task = task }
    }

    /// 탭 하나를 처음부터 다시 로드한다(첫 로드·재시도·"컬렉션 만들기" 복귀 공통 — 이 화면엔
    /// 필터/정렬 UI가 없다). `CreateCollectionView`는 성공 콜백 없이 자기완결 dismiss만 하므로,
    /// 복귀 시엔 성공 여부와 무관하게 무조건 `.mine`을 다시 로드한다(최소 diff, 3B 판단).
    func reload(_ tab: CollectionListTab) {
        updateBookkeeping(for: tab) { book in
            book.generation += 1
            book.task?.cancel()
            book.nextCursor = nil
            book.hasNext = true
        }
        updateContent(for: tab) {
            $0.items = []
            $0.isLoading = true
            $0.isLoadingMore = false
            $0.loadFailed = nil
        }
        let generation = bookkeeping(for: tab).generation
        let task = Task { await loadPage(tab: tab, cursor: nil, generation: generation) }
        updateBookkeeping(for: tab) { $0.task = task }
    }
}

// MARK: - UseCase Handling

private extension CollectionListViewModel {

    /// 탭 하나의 페이지 로드. `cursor == nil`이면 첫 페이지(목록 교체), 아니면 다음 페이지(append).
    func loadPage(tab: CollectionListTab, cursor: String?, generation: Int) async {
        defer {
            if bookkeeping(for: tab).generation == generation {
                updateBookkeeping(for: tab) { $0.task = nil }
                updateContent(for: tab) {
                    $0.isLoading = false
                    $0.isLoadingMore = false
                }
            }
        }
        do {
            let (page, totalCount) = try await fetch(tab: tab, cursor: cursor)
            guard bookkeeping(for: tab).generation == generation, !Task.isCancelled else { return }
            updateContent(for: tab) { content in
                if cursor == nil {
                    content.items = page.items
                } else {
                    content.items.append(contentsOf: page.items)
                }
                content.totalCount = totalCount
                content.loadFailed = nil
            }
            updateBookkeeping(for: tab) {
                $0.nextCursor = page.nextCursor
                $0.hasNext = page.hasNext
                $0.hasLoaded = true
            }
        } catch {
            guard bookkeeping(for: tab).generation == generation, !Task.isCancelled else { return }
            // 인증 만료는 실패 뷰/토스트 대신 로그인 유도로 일원화 — 실패 플래그보다 먼저 거른다.
            if routeToLoginIfAuthenticationRequired(error) { return }
            if cursor == nil {
                updateContent(for: tab) { $0.loadFailed = (error as? RepositoryError) ?? .unknown }
                logger?.error("CollectionList 실패(\(tab), load): \(String(describing: error))")
            } else {
                presentError(error, tab: tab, as: .loadMoreFailed)
            }
        }
    }

    func fetch(tab: CollectionListTab, cursor: String?) async throws(RepositoryError) -> (CursorPaginated<CollectionCard>, Int) {
        switch tab {
        case .mine:
            return try await loadCollectionsUseCase.execute(userID: userID, cursor: cursor, size: Self.pageSize)
        case .liked:
            return try await loadLikedCollectionsUseCase.execute(cursor: cursor, size: Self.pageSize)
        }
    }
}

// MARK: - Error Mapping

private extension CollectionListViewModel {

    func presentError(_ error: Error, tab: CollectionListTab, as presented: CollectionListToast) {
        if routeToLoginIfAuthenticationRequired(error) { return }
        logger?.error("CollectionList 실패(\(tab), \(presented)): \(String(describing: error))")
        if state.presentedToast != nil { return }
        state.presentedToast = presented
    }

    /// push 후 dismiss되는 화면(탭 콘텐츠 아님)이라 `CollectionMyLibrarySelectViewModel`과 동일하게
    /// 1회성 신호로 충분 — `.consumeAuthenticationRequired` 같은 소진 처리가 필요 없다.
    func routeToLoginIfAuthenticationRequired(_ error: Error) -> Bool {
        guard (error as? RepositoryError) == .authenticationRequired else { return false }
        state.requiresAuthentication = true
        return true
    }
}

// MARK: - Tab Bookkeeping Access

private extension CollectionListViewModel {

    // `LoadBookkeeping`이 `private` 타입이라, `private extension`의 기본 접근수준(fileprivate)보다
    // 좁게 명시해야 한다(안 그러면 "결과/파라미터가 private 타입을 쓰는데 메서드가 private이 아니다" 에러).
    private func bookkeeping(for tab: CollectionListTab) -> LoadBookkeeping {
        switch tab {
        case .mine: mineBookkeeping
        case .liked: likedBookkeeping
        }
    }

    private func updateBookkeeping(for tab: CollectionListTab, _ update: (inout LoadBookkeeping) -> Void) {
        switch tab {
        case .mine: update(&mineBookkeeping)
        case .liked: update(&likedBookkeeping)
        }
    }

    func content(for tab: CollectionListTab) -> TabContent {
        switch tab {
        case .mine: state.mine
        case .liked: state.liked
        }
    }

    func updateContent(for tab: CollectionListTab, _ update: (inout TabContent) -> Void) {
        switch tab {
        case .mine: update(&state.mine)
        case .liked: update(&state.liked)
        }
    }
}
