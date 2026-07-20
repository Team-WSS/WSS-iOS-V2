//
//  ClearRecentSearchWordsUseCase.swift
//  SearchDomain
//
//  Created by Seoyeon Choi on 7/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol ClearRecentSearchWordsUseCase {
    func execute() async throws(RepositoryError)
}

public final class DefaultClearRecentSearchWordsUseCase: ClearRecentSearchWordsUseCase {

    private let recentSearchRepository: RecentSearchRepository

    public init(recentSearchRepository: RecentSearchRepository) {
        self.recentSearchRepository = recentSearchRepository
    }

    public func execute() async throws(RepositoryError) {
        try await recentSearchRepository.clearRecentSearchWords()
    }
}
