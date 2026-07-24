//
//  SearchKeywordViewModel.swift
//  KeywordFeature
//
//  Created by Seoyeon Choi on 7/24/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import BaseDomain
import Logger

@MainActor
@Observable
final class SearchKeywordViewModel {

    // MARK: - State

    struct State {
        var groups: [KeywordGroup] = []
        var presentedError: PresentedError?
    }

    enum PresentedError: Equatable { case unknown }

    // MARK: - Action

    enum Action {
        case load
        case dismissError
    }

    // MARK: - Output

    private(set) var state = State()

    // MARK: - Dependency

    private let logger: Logger?

    // BaseDomain (Keyword)
    private let loadTotalKeywordsUseCase: LoadTotalKeywordsUseCase

    // MARK: - Init

    init(loadTotalKeywordsUseCase: LoadTotalKeywordsUseCase, logger: Logger? = nil) {
        self.loadTotalKeywordsUseCase = loadTotalKeywordsUseCase
        self.logger = logger
    }

    // MARK: - handle

    func handle(_ action: Action) {
        switch action {
        case .load:
            load()
        case .dismissError:
            state.presentedError = nil
        }
    }
}

// MARK: - Action Handling

private extension SearchKeywordViewModel {
    func load() {
        Task { await loadKeywordGroups() }
    }
}

// MARK: - UseCase Handling

private extension SearchKeywordViewModel {
    func loadKeywordGroups() async {
        do {
            state.groups = try await loadTotalKeywordsUseCase.execute()
        } catch {
            presentError(error)
        }
    }
}

// MARK: - Error Mapping

private extension SearchKeywordViewModel {
    func presentError(_ error: Error) {
        logger?.error("SearchKeyword 키워드 로드 실패: \(String(describing: error))")
        state.presentedError = .unknown
    }
}
