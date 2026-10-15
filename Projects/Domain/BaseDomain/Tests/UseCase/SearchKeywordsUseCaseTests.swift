//
//  SearchKeywordsUseCaseTests.swift
//  BaseDomain
//
//  Created by Seoyeon Choi on 2/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

import BaseDomain
import BaseDomainTesting

@Suite("키워드 검색")
struct SearchKeywordsUseCaseTests {

    private let regression = Keyword(id: KeywordID(11), name: "회귀")
    private let academy = Keyword(id: KeywordID(12), name: "아카데미")

    @Test("처음 검색에 성공하면 동기화하지 않는다")
    func firstSearchSucceedsWithoutSync() async throws {
        let repository = MockKeywordRepository()
        repository.searchKeywordsResults["회귀"] = .success([KeywordGroup(category: .material, keywords: [regression])])

        let keywords = try await DefaultSearchKeywordUseCase(keywordRepository: repository).execute(searchText: "회귀")

        #expect(keywords == [regression])
        #expect(repository.syncKeywordsCallCount == 0)
    }

    @Test("검색에 실패하면 동기화한 뒤 다시 검색한 결과를 준다")
    func failedSearchSyncsAndSearchesAgain() async throws {
        let repository = MockKeywordRepository()
        repository.searchKeywordsResults["회귀"] = .failure(.notFound)
        repository.searchKeywordsResultsAfterSync["회귀"] = .success([KeywordGroup(category: .material, keywords: [regression])])

        let keywords = try await DefaultSearchKeywordUseCase(keywordRepository: repository).execute(searchText: "회귀")

        #expect(keywords == [regression])
    }

    @Test("동기화한 뒤에도 실패하면 그 에러를 전한다")
    func failedAfterSyncPassesError() async {
        let repository = MockKeywordRepository()
        repository.searchKeywordsResults["회귀"] = .failure(.notFound)
        repository.searchKeywordsResultsAfterSync["회귀"] = .failure(.networkUnavailable)
        let useCase = DefaultSearchKeywordUseCase(keywordRepository: repository)

        await #expect(throws: RepositoryError.networkUnavailable) {
            try await useCase.execute(searchText: "회귀")
        }
    }

    @Test("묶음별 검색 결과를 키워드 목록 하나로 펼친다")
    func flattensGroupsIntoOneList() async throws {
        let repository = MockKeywordRepository()
        repository.searchKeywordsResults["아"] = .success([
            KeywordGroup(category: .material, keywords: [regression]),
            KeywordGroup(category: .worldview, keywords: [academy])
        ])

        let keywords = try await DefaultSearchKeywordUseCase(keywordRepository: repository).execute(searchText: "아")

        #expect(keywords == [regression, academy])
    }
}
