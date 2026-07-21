//
//  DetailSearchResultViewModel.swift
//  SearchFeature
//
//  Created by Seoyeon Choi on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import NovelDomain
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
    }

    // MARK: - Output

    private(set) var state: State

    // MARK: - Property

    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    @ObservationIgnored private var loadMoreTask: Task<Void, Never>?
    @ObservationIgnored private var nextPage = 0

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
        }
    }
}

// MARK: - Action Handling

private extension DetailSearchResultViewModel {
    func load() {
        guard !hasLoaded, loadTask == nil else { return }
        state.isLoading = true
        state.hasLoadError = false
        loadTask = Task { await loadResult() }
    }

    /// 그리드 마지막 행이 보일 때 View가 호출(무한스크롤). 다음 페이지가 없거나 이미 로딩 중이면 무시.
    func loadMore() {
        guard hasLoaded, state.hasNextPage, loadTask == nil, loadMoreTask == nil else { return }
        state.isLoadingMore = true
        loadMoreTask = Task { await loadMoreResult() }
    }
}

// MARK: - UseCase Handling

private extension DetailSearchResultViewModel {
    func loadResult() async {
        defer {
            loadTask = nil
            state.isLoading = false
        }

        do {
            let (paginated, resultCount) = try await searchNovelUseCase.searchByFilter(state.filter, page: 0)
            guard !Task.isCancelled else { return }
            state.novels = paginated.items
            state.totalNovelCount = resultCount
            state.hasNextPage = paginated.hasNext
            nextPage = 1
            hasLoaded = true
        } catch {
            guard !Task.isCancelled else { return }
            logger?.error("필터 검색 실패: \(String(describing: error))")
            state.hasLoadError = true
        }
    }

    func loadMoreResult() async {
        defer {
            loadMoreTask = nil
            state.isLoadingMore = false
        }

        do {
            let (paginated, resultCount) = try await searchNovelUseCase.searchByFilter(state.filter, page: nextPage)
            guard !Task.isCancelled else { return }
            state.novels.append(contentsOf: paginated.items)
            state.totalNovelCount = resultCount
            state.hasNextPage = paginated.hasNext
            nextPage += 1
        } catch {
            guard !Task.isCancelled else { return }
            logger?.error("필터 검색 다음 페이지 실패: \(String(describing: error))")
        }
    }
}
