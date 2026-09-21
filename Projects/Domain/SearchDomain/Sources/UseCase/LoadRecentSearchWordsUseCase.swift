//
//  LoadRecentSearchWordsUseCase.swift
//  SearchDomain
//
//  Created by Seoyeon Choi on 7/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadRecentSearchWordsUseCase: Sendable {
    func execute() async throws(RepositoryError) -> [RecentSearchWord]
}

public final class DefaultLoadRecentSearchWordsUseCase: LoadRecentSearchWordsUseCase {

    private let recentSearchRepository: RecentSearchRepository

    public init(recentSearchRepository: RecentSearchRepository) {
        self.recentSearchRepository = recentSearchRepository
    }

    public func execute() async throws(RepositoryError) -> [RecentSearchWord] {
        try await recentSearchRepository.fetchRecentSearchWords()
    }
}
