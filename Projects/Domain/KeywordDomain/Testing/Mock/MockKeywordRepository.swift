//
//  MockKeywordRepository.swift
//  KeywordDomain
//
//  Created by Seoyeon Choi on 2/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import KeywordDomain
import BaseDomain

public final class MockKeywordRepository: KeywordRepository {

    public var fetchKeywordsResult: Result<[KeywordGroup], RepositoryError> = .success([])
    public var searchKeywordsResult: Result<[Keyword], RepositoryError> = .success([])

    public private(set) var fetchKeywordsCallCount = 0
    public private(set) var searchedQueries: [String] = []
    
    public init() {}

    public func fetchKeywords() async throws(RepositoryError) -> [KeywordGroup] {
        fetchKeywordsCallCount += 1
        switch fetchKeywordsResult {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }

    public func searchKeywords(_ query: String) async throws(RepositoryError) -> [Keyword] {
        searchedQueries.append(query)
        switch searchKeywordsResult {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }
}
