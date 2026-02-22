//
//  SearchKeywordsUsecaseTests.swift
//  KeywordDomain
//
//  Created by Seoyeon Choi on 2/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import KeywordDomain
@testable import BaseDomain

@Suite
struct SearchKeywordsUsecaseTests {

    @Test("키워드 검색 시 결과를 성공적으로 반환한다.")
    func searchKeywordsSuccess() async throws {
        let mock = MockKeywordRepository()
        mock.searchKeywordsResult = .success([
            makeKeyword(id: 1, name: "삼국지"),
            makeKeyword(id: 2, name: "성장")
        ])

        let usecase = DefaultSearchKeywordUsecase(keywordRepository: mock)
        let result = try await usecase.execute(searchText: "삼국지")

        #expect(result.count == 2)
        #expect(result.first?.name == "삼국지")
        #expect(mock.searchedQueries.contains("삼국지"))
    }

    @Test("검색 결과가 없어도 빈 배열을 반환한다.")
    func searchKeywordsEmptyResult() async throws {
        let mock = MockKeywordRepository()
        mock.searchKeywordsResult = .success([])

        let usecase = DefaultSearchKeywordUsecase(keywordRepository: mock)
        let result = try await usecase.execute(searchText: "존재하지않는키워드")

        #expect(result.isEmpty)
        #expect(mock.searchedQueries.contains("존재하지않는키워드"))
    }

    @Test("검색어가 레포지토리로 정확히 전달된다.")
    func searchQueryIsPassedToRepository() async throws {
        let mock = MockKeywordRepository()
        mock.searchKeywordsResult = .success([])

        let usecase = DefaultSearchKeywordUsecase(keywordRepository: mock)
        let query = "판타지"

        _ = try await usecase.execute(searchText: query)

        #expect(mock.searchedQueries.last == query)
    }

    @Test("키워드 검색 실패 시 에러를 던진다.")
    func searchKeywordsFailureThrows() async {
        let mock = MockKeywordRepository()
        mock.searchKeywordsResult = .failure(MockKeywordRepository.MockError.searchFailed)

        let usecase = DefaultSearchKeywordUsecase(keywordRepository: mock)

        await #expect(throws: MockKeywordRepository.MockError.searchFailed) {
            try await usecase.execute(searchText: "집착")
        }

        #expect(mock.searchedQueries.contains("집착"))
    }
}

extension SearchKeywordsUsecaseTests {
    private func makeKeyword(id: Int, name: String) -> Keyword {
        Keyword(id: KeywordID(id), name: name)
    }
}
