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

    public var fetchKeywordsResult: Result<[KeywordGroup], Error> = .success([])
    public var searchKeywordsResult: Result<[Keyword], Error> = .success([])

    public private(set) var fetchKeywordsCallCount = 0
    public private(set) var searchKeywordsCallCount = 0
    public private(set) var lastSearchQuery: String?

    public init() {}

    public func fetchKeywords() async throws -> [KeywordGroup] {
        fetchKeywordsCallCount += 1
        return try fetchKeywordsResult.get()
    }

    public func searchKeywords(_ query: String) async throws -> [Keyword] {
        searchKeywordsCallCount += 1
        lastSearchQuery = query
        return try searchKeywordsResult.get()
    }
}
