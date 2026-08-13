//
//  DetailSearchResultViewModel.swift
//  SearchFeature
//
//  Created by Seoyeon Choi on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import SearchDomain
import Logger

@MainActor
@Observable
final class DetailSearchResultViewModel {

    // MARK: - State

    struct State {
        var filter: SearchFilter
        var novels: [Novel] = []
        var totalNovelCount: Int = 0
        var isLoading = false
        var hasLoadError = false
        var hasNextPage = false
        var isLoadingMore = false
    }

    // MARK: - Action

    enum Action {
        case load
        case loadMore
        case updateFilter(SearchFilter)
    }

    // MARK: - Output

    private(set) var state: State

    // MARK: - Property

    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    @ObservationIgnored private var loadMoreTask: Task<Void, Never>?
    @ObservationIgnored private var nextPage = 0
    /// `updateFilter`로 새 로드가 시작될 때마다 증가 — 취소된 이전 `Task`의 `defer`가 뒤늦게 끝나며
    /// 새 로드의 `state`(`isLoading`/`loadTask` 등)를 덮어쓰지 않도록 세대를 비교한다(LibraryFeature의
    /// `reloadFromScratch()` 세대 카운터와 동일한 함정 방지).
    @ObservationIgnored private var loadGeneration = 0

    // MARK: - Dependency

    private let logger: Logger?

    // NovelDomain
    private let searchNovelUseCase: SearchNovelUseCase

    // MARK: - Init

    init(filter: SearchFilter, searchNovelUseCase: SearchNovelUseCase, logger: Logger? = nil) {
        self.searchNovelUseCase = searchNovelUseCase
        self.logger = logger
        self.state = State(filter: filter)
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .load:
            load()
        case .loadMore:
            loadMore()
        case .updateFilter(let filter):
            updateFilter(filter)
        }
    }
}

// MARK: - Action Handling

private extension DetailSearchResultViewModel {
    func load() {
        guard !hasLoaded, loadTask == nil else { return }
        state.isLoading = true
        state.hasLoadError = false
        let generation = loadGeneration
        loadTask = Task { await loadResult(generation: generation) }
    }

    /// 그리드 마지막 행이 보일 때 View가 호출(무한스크롤). 다음 페이지가 없거나 이미 로딩 중이면 무시.
    func loadMore() {
        guard hasLoaded, state.hasNextPage, loadTask == nil, loadMoreTask == nil else { return }
        state.isLoadingMore = true
        let generation = loadGeneration
        loadMoreTask = Task { await loadMoreResult(generation: generation) }
    }

    /// 상세탐색 필터 화면("작품 찾기")에서 필터를 다시 확정하고 돌아왔을 때 호출 — 처음부터 다시 로드한다.
    func updateFilter(_ newFilter: SearchFilter) {
        loadGeneration += 1
        loadTask?.cancel()
        loadMoreTask?.cancel()
        loadTask = nil
        loadMoreTask = nil
        hasLoaded = false
        nextPage = 0
        state.filter = newFilter
        state.novels = []
        state.totalNovelCount = 0
        state.hasNextPage = false
        state.isLoadingMore = false
        load()
    }
}

// MARK: - UseCase Handling

private extension DetailSearchResultViewModel {
    func loadResult(generation: Int) async {
        defer {
            if generation == loadGeneration {
                loadTask = nil
                state.isLoading = false
            }
        }

        do {
            let (paginated, resultCount) = try await searchNovelUseCase.searchByFilter(state.filter, page: 0)
            guard !Task.isCancelled, generation == loadGeneration else { return }
            state.novels = paginated.items
            state.totalNovelCount = resultCount
            state.hasNextPage = paginated.hasNext
            nextPage = 1
            hasLoaded = true
        } catch {
            guard !Task.isCancelled, generation == loadGeneration else { return }
            logger?.error("필터 검색 실패: \(String(describing: error))")
            state.hasLoadError = true
        }
    }

    func loadMoreResult(generation: Int) async {
        defer {
            if generation == loadGeneration {
                loadMoreTask = nil
                state.isLoadingMore = false
            }
        }

        do {
            let (paginated, resultCount) = try await searchNovelUseCase.searchByFilter(state.filter, page: nextPage)
            guard !Task.isCancelled, generation == loadGeneration else { return }
            state.novels.append(contentsOf: paginated.items)
            state.totalNovelCount = resultCount
            state.hasNextPage = paginated.hasNext
            nextPage += 1
        } catch {
            guard !Task.isCancelled, generation == loadGeneration else { return }
            logger?.error("필터 검색 다음 페이지 실패: \(String(describing: error))")
        }
    }
}
