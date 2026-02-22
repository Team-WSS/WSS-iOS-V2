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

final class MockKeywordRepository: KeywordRepository {

    enum MockError: Error {
        case fetchFailed
        case searchFailed
    }

    var fetchKeywordsResult: Result<[KeywordGroup], Error> = .success([])
    var searchKeywordsResult: Result<[Keyword], Error> = .success([])

    private(set) var fetchKeywordsCallCount = 0
    private(set) var searchedQueries: [String] = []

    func fetchKeywords() async throws -> [KeywordGroup] {
        fetchKeywordsCallCount += 1
        switch fetchKeywordsResult {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }

    func searchKeywords(_ query: String) async throws -> [Keyword] {
        searchedQueries.append(query)
        switch searchKeywordsResult {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }
}
