//
//  PublicCollectionListViewModel.swift
//  CollectionFeature
//
//  Created by Guryss on 9/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import CollectionDomain
import Logger

/// 전체 컬렉션뷰 — 모든 사용자의 공개 컬렉션을 최신순 무한 스크롤로 본다. 홈 "컬렉션 모음.zip" 섹션
/// 제목 탭에서 진입한다(#283). 화면 동작 계약은 `CollectionFeature/CLAUDE.md` 참고.
@MainActor
@Observable
final class PublicCollectionListViewModel {

    // MARK: - State

    struct State {
        var items: [PublicCollectionCard] = []
        /// 초기값 true — onAppear의 `.load`보다 첫 body 평가가 먼저라, false로 시작하면 로드 시작 전
        /// 한 프레임 빈 상태가 스친다(`CollectionListViewModel`과 동일 이유).
        var isLoading = true
        var isLoadingMore = false
        var loadFailed: RepositoryError?
        var requiresAuthentication = false
    }

    // MARK: - Action

    enum Action {
        case load
        case loadMore
        /// 당겨서 새로고침 — 목록을 비우지 않고 첫 페이지로 교체한다(비우면 인디케이터 아래가 깜빡인다).
        case refresh
        /// 실패 뷰(`NetworkErrorView`)의 재시도 — 처음부터 다시 세운다.
        case retry
    }

    // MARK: - Output

    private(set) var state = State()

    // MARK: - Property

    /// 커서+generation 부기(View가 안 보는 값) — 진행 중이던 로드의 늦은 응답이 새 목록을 덮지 않게 한다.
    @ObservationIgnored private var nextCursor: String?
    @ObservationIgnored private var hasNext = true
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private var loadTask: Task<Void, Never>?

    /// 서버 권장 페이지 크기가 따로 없어 화면이 정한다(`CollectionListViewModel`과 같은 값).
    private static let pageSize = 20

    // MARK: - Dependency

    private let logger: Logger?

    // CollectionDomain
    private let loadPublicCollectionsUseCase: LoadPublicCollectionsUseCase

    // MARK: - Init

    init(
        loadPublicCollectionsUseCase: LoadPublicCollectionsUseCase,
        logger: Logger? = nil
    ) {
        self.loadPublicCollectionsUseCase = loadPublicCollectionsUseCase
        self.logger = logger
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .load:
            guard loadTask == nil, state.items.isEmpty else { return }
            reload(clearingItems: true)
        case .loadMore:
            loadMore()
        case .refresh:
            reload(clearingItems: false)
        case .retry:
            reload(clearingItems: true)
        }
    }

    /// `.refreshable`이 인디케이터를 로드가 끝날 때까지 붙잡도록 진행 중 로드를 기다린다
    /// (`handle`은 동기 반환 — `SosoFeedViewModel.awaitFeedsLoad`와 같은 이유).
    func awaitLoad() async {
        await loadTask?.value
    }
}

// MARK: - Action Handling

private extension PublicCollectionListViewModel {

    func reload(clearingItems: Bool) {
        generation += 1
        loadTask?.cancel()
        nextCursor = nil
        hasNext = true

        if clearingItems {
            state.items = []
            state.isLoading = true
        }
        state.isLoadingMore = false
        state.loadFailed = nil

        let generation = generation
        loadTask = Task { await loadPage(cursor: nil, generation: generation) }
    }

    /// 다음 페이지. 커서는 직전 응답의 `nextCursor`를 그대로 왕복한다.
    func loadMore() {
        guard hasNext, loadTask == nil, !state.isLoading, state.loadFailed == nil,
              let cursor = nextCursor else { return }
        state.isLoadingMore = true
        let generation = generation
        loadTask = Task { await loadPage(cursor: cursor, generation: generation) }
    }
}

// MARK: - UseCase Handling

private extension PublicCollectionListViewModel {

    /// `cursor == nil`이면 첫 페이지(목록 교체), 아니면 다음 페이지(append).
    func loadPage(cursor: String?, generation: Int) async {
        defer {
            if self.generation == generation {
                loadTask = nil
                state.isLoading = false
                state.isLoadingMore = false
            }
        }
        do {
            let page = try await loadPublicCollectionsUseCase.execute(cursor: cursor, size: Self.pageSize)
            guard self.generation == generation, !Task.isCancelled else { return }
            if cursor == nil {
                state.items = page.items
            } else {
                state.items.append(contentsOf: page.items)
            }
            nextCursor = page.nextCursor
            hasNext = page.hasNext
        } catch {
            guard self.generation == generation, !Task.isCancelled else { return }
            presentLoadFailure(error, cursor: cursor)
        }
    }
}

// MARK: - Error Mapping

private extension PublicCollectionListViewModel {

    /// 첫 페이지·더보기·새로고침 모두 실패 뷰로 표현한다 — 목록이 남아 있어도 걷어낸다
    /// (Feature 레이어 "로드 실패 표현 계약": 토스트는 사라지면 재시도 수단이 없다).
    func presentLoadFailure(_ error: Error, cursor: String?) {
        // 인증 만료는 실패 뷰 대신 로그인 유도로 일원화 — 실패 플래그보다 먼저 거른다.
        guard (error as? RepositoryError) != .authenticationRequired else {
            state.requiresAuthentication = true
            return
        }
        logger?.error("PublicCollectionList 실패(\(cursor == nil ? "load" : "loadMore")): \(String(describing: error))")
        state.loadFailed = (error as? RepositoryError) ?? .unknown
    }
}
