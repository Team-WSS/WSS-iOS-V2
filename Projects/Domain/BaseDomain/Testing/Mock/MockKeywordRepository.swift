//
//  MockKeywordRepository.swift
//  BaseDomain
//
//  Created by Seoyeon Choi on 2/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public final class MockKeywordRepository: KeywordRepository {
    public var fetchKeywordsResult: Result<[KeywordGroup], RepositoryError> = .success([])
    /// 설정하면 `fetchKeywords()` 호출마다 순서대로 하나씩 소비한다(마지막 값은 이후 호출에 계속 반환).
    /// 캐시 미스 → 동기화 → 재조회처럼 호출마다 결과가 달라야 하는 시나리오 검증용. 미설정 시 `fetchKeywordsResult`를 매번 사용.
    public var fetchKeywordsResults: [Result<[KeywordGroup], RepositoryError>]?
    public var searchKeywordsResult: Result<[KeywordGroup], RepositoryError> = .success([])
    public var fetchPopularKeywordsResult: Result<PopularKeywords, RepositoryError> = .success(PopularKeywords(keywords: []))

    public private(set) var fetchKeywordsCallCount = 0
    public private(set) var syncKeywordsCallCount = 0
    public private(set) var searchedQueries: [String] = []
    public private(set) var fetchPopularKeywordsCallCount = 0

    public init() {}

    public func fetchKeywords() async throws(RepositoryError) -> [KeywordGroup] {
        fetchKeywordsCallCount += 1
        let result: Result<[KeywordGroup], RepositoryError>
        if let sequence = fetchKeywordsResults, !sequence.isEmpty {
            let index = min(fetchKeywordsCallCount, sequence.count) - 1
            result = sequence[index]
        } else {
            result = fetchKeywordsResult
        }
        switch result {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }

    public func searchKeywords(_ query: String) async throws(RepositoryError) -> [KeywordGroup] {
        searchedQueries.append(query)
        switch searchKeywordsResult {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }

    public func syncKeywords() async {
        syncKeywordsCallCount += 1
    }

    public func fetchPopularKeywords() async throws(RepositoryError) -> PopularKeywords {
        fetchPopularKeywordsCallCount += 1
        switch fetchPopularKeywordsResult {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }
}
