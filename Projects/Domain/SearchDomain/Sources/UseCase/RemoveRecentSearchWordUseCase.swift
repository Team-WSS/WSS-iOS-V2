//
//  RemoveRecentSearchWordUseCase.swift
//  SearchDomain
//
//  Created by Seoyeon Choi on 7/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol RemoveRecentSearchWordUseCase {
    func execute(word: RecentSearchWord) async throws(RepositoryError)
}

public final class DefaultRemoveRecentSearchWordUseCase: RemoveRecentSearchWordUseCase {

    private let recentSearchRepository: RecentSearchRepository

    public init(recentSearchRepository: RecentSearchRepository) {
        self.recentSearchRepository = recentSearchRepository
    }

    public func execute(word: RecentSearchWord) async throws(RepositoryError) {
        try await recentSearchRepository.removeRecentSearchWord(word)
    }
}
