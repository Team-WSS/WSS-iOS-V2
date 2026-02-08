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
   
    var fetchKeywordsResult: Result<[KeywordGroup], Error> = .success([])
    var searchKeywordsResult: Result<[Keyword], Error> = .success([])

    private(set) var fetchKeywordsCallCount = 0
    private(set) var searchKeywordsCallCount = 0
    private(set) var lastSearchQuery: String?
    
    func fetchKeywords() async throws -> [KeywordGroup] {
        fetchKeywordsCallCount += 1
        return try fetchKeywordsResult.get()
    }
    
    func searchKeywords(_ query: String) async throws -> [Keyword] {
        searchKeywordsCallCount += 1
        lastSearchQuery = query
        return try searchKeywordsResult.get()
    }
}
