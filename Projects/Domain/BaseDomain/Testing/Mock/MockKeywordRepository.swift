//
//  MockKeywordRepository.swift
//  BaseDomain
//
//  Created by Seoyeon Choi on 2/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

/// 키워드 저장소 가짜 객체.
/// 조회(`fetchKeywords`·`searchKeywords`·`fetchPopularKeywords`)는 정해 둔 값만 돌려주고 호출을 기록하지 않는다(Stub).
/// 검색은 **검색어마다** 답을 정해 둔다 — 정해 두지 않은 검색어엔 빈 목록을 준다. 그래서 검색어를 잘못 넘기면 결과가 달라진다.
/// 실제 저장소처럼 **동기화했는지에 따라** 답이 바뀐다 — 동기화 전엔 `…Result`, 동기화 뒤엔 `…ResultAfterSync`(없으면 `…Result`).
/// 동기화(`syncKeywords`)는 명령이라 호출 횟수를 기록한다(Mock).
public final class MockKeywordRepository: KeywordRepository {
    public var fetchKeywordsResult: Result<[KeywordGroup], RepositoryError> = .success([])
    public var fetchKeywordsResultAfterSync: Result<[KeywordGroup], RepositoryError>?
    public var searchKeywordsResults: [String: Result<[KeywordGroup], RepositoryError>] = [:]
    public var searchKeywordsResultsAfterSync: [String: Result<[KeywordGroup], RepositoryError>] = [:]
    public var fetchPopularKeywordsResult: Result<PopularKeywords, RepositoryError> = .success(PopularKeywords(keywords: []))

    public private(set) var syncKeywordsCallCount = 0

    public init() {}

    public func fetchKeywords() async throws(RepositoryError) -> [KeywordGroup] {
        try Self.value(of: currentResult(before: fetchKeywordsResult, after: fetchKeywordsResultAfterSync))
    }

    public func searchKeywords(_ query: String) async throws(RepositoryError) -> [KeywordGroup] {
        try Self.value(of: currentResult(
            before: searchKeywordsResults[query] ?? .success([]),
            after: searchKeywordsResultsAfterSync[query]
        ))
    }

    public func syncKeywords() async {
        syncKeywordsCallCount += 1
    }

    public func fetchPopularKeywords() async throws(RepositoryError) -> PopularKeywords {
        try Self.value(of: fetchPopularKeywordsResult)
    }

    private func currentResult<Value>(
        before: Result<Value, RepositoryError>,
        after: Result<Value, RepositoryError>?
    ) -> Result<Value, RepositoryError> {
        guard syncKeywordsCallCount > 0, let after else { return before }
        return after
    }

    private static func value<Value>(of result: Result<Value, RepositoryError>) throws(RepositoryError) -> Value {
        switch result {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }
}
