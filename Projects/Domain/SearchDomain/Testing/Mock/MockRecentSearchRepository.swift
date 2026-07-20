//
//  MockRecentSearchRepository.swift
//  SearchDomain
//
//  Created by Seoyeon Choi on 7/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import SearchDomain
import BaseDomain

public final class MockRecentSearchRepository: RecentSearchRepository {

    public var fetchRecentSearchWordsResult: Result<[RecentSearchWord], RepositoryError> = .success([])
    public var removeRecentSearchWordResult: Result<Void, RepositoryError> = .success(())
    public var clearRecentSearchWordsResult: Result<Void, RepositoryError> = .success(())

    public private(set) var removedWords: [RecentSearchWord] = []
    public private(set) var clearCallCount = 0

    public init() {}

    public func fetchRecentSearchWords() async throws(RepositoryError) -> [RecentSearchWord] {
        try fetchRecentSearchWordsResult.get()
    }

    public func removeRecentSearchWord(_ word: RecentSearchWord) async throws(RepositoryError) {
        removedWords.append(word)
        try removeRecentSearchWordResult.get()
    }

    public func clearRecentSearchWords() async throws(RepositoryError) {
        clearCallCount += 1
        try clearRecentSearchWordsResult.get()
    }
}
