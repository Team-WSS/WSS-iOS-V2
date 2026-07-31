//
//  SearchKeywordsUseCaseTests.swift
//  BaseDomain
//
//  Created by Seoyeon Choi on 2/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

@testable import BaseDomain
import BaseDomainTesting

@Suite
struct SearchKeywordsUseCaseTests {

    @Test("키워드 검색 시 결과를 성공적으로 반환한다.")
    func searchKeywordsSuccess() async throws {
        let mock = MockKeywordRepository()
        mock.searchKeywordsResult = .success([
            KeywordGroup(category: .worldview, keywords: [
                makeKeyword(id: 1, name: "삼국지"),
                makeKeyword(id: 2, name: "성장")
            ])
        ])

        let usecase = DefaultSearchKeywordUseCase(keywordRepository: mock)
        let result = try await usecase.execute(searchText: "삼국지")

        #expect(result.count == 2)
        #expect(result.first?.name == "삼국지")
        #expect(mock.searchedQueries.contains("삼국지"))
    }

    @Test("검색 결과가 없어도 빈 배열을 반환한다.")
    func searchKeywordsEmptyResult() async throws {
        let mock = MockKeywordRepository()
        mock.searchKeywordsResult = .success([])

        let usecase = DefaultSearchKeywordUseCase(keywordRepository: mock)
        let result = try await usecase.execute(searchText: "존재하지않는키워드")

        #expect(result.isEmpty)
        #expect(mock.searchedQueries.contains("존재하지않는키워드"))
    }

    @Test("검색어가 레포지토리로 정확히 전달된다.")
    func searchQueryIsPassedToRepository() async throws {
        let mock = MockKeywordRepository()
        mock.searchKeywordsResult = .success([])

        let usecase = DefaultSearchKeywordUseCase(keywordRepository: mock)
        let query = "판타지"

        _ = try await usecase.execute(searchText: query)

        #expect(mock.searchedQueries.last == query)
    }

    @Test("키워드 검색이 동기화 후 재조회에도 계속 실패하면 에러를 던진다.")
    func searchKeywordsFailureThrows() async {
        let mock = MockKeywordRepository()
        mock.searchKeywordsResult = .failure(RepositoryError.unknown)

        let usecase = DefaultSearchKeywordUseCase(keywordRepository: mock)

        await #expect(throws: RepositoryError.unknown) {
            try await usecase.execute(searchText: "집착")
        }

        #expect(mock.searchedQueries.contains("집착"))
        // 최초 조회 실패 → 동기화 1회 → 재조회까지 시도한 뒤에도 실패하면 그 에러를 던진다.
        #expect(mock.searchKeywordsCallCount == 2)
        #expect(mock.syncKeywordsCallCount == 1)
    }

    @Test("로컬 캐시가 비어있으면 동기화 후 재조회로 복구한다.")
    func searchKeywordsRecoversAfterSyncOnCacheMiss() async throws {
        let mock = MockKeywordRepository()
        mock.searchKeywordsResults = [
            .failure(.unknown),
            .success([
                KeywordGroup(category: .worldview, keywords: [makeKeyword(id: 1, name: "삼국지")])
            ])
        ]

        let usecase = DefaultSearchKeywordUseCase(keywordRepository: mock)
        let result = try await usecase.execute(searchText: "삼국지")

        #expect(result.count == 1)
        #expect(result.first?.name == "삼국지")
        #expect(mock.searchKeywordsCallCount == 2)
        #expect(mock.syncKeywordsCallCount == 1)
    }
}

extension SearchKeywordsUseCaseTests {
    private func makeKeyword(id: Int, name: String) -> Keyword {
        Keyword(id: KeywordID(id), name: name)
    }
}
