//
//  SearchAutoCompletionWordsUseCaseTests.swift
//  SearchDomain
//
//  Created by Seoyeon Choi on 7/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import SearchDomain
import SearchDomainTesting
import BaseDomain

@Suite
struct SearchAutoCompletionWordsUseCaseTests {

    @Test("검색어로 제목 자동완성 후보를 조회한다")
    func searchesAutoCompletionWords() async throws {
        let mock = MockSearchAutoCompletionRepository()
        mock.fetchAutoCompletionWordsResult = .success([
            SearchAutoCompletionWord(word: "환생한 영애님"),
            SearchAutoCompletionWord(word: "환생물 정주행")
        ])

        let usecase = DefaultSearchAutoCompletionWordsUseCase(searchAutoCompletionRepository: mock)
        let result = try await usecase.execute(searchText: "환생")

        #expect(result.count == 2)
        #expect(mock.searchedTexts.last == "환생")
    }

    @Test("앞뒤 공백을 제거하고 조회한다")
    func trimsWhitespaceBeforeSearching() async throws {
        let mock = MockSearchAutoCompletionRepository()
        mock.fetchAutoCompletionWordsResult = .success([])

        let usecase = DefaultSearchAutoCompletionWordsUseCase(searchAutoCompletionRepository: mock)
        _ = try await usecase.execute(searchText: "  환생  ")

        #expect(mock.searchedTexts.last == "환생")
    }

    @Test("빈 검색어는 서버 호출 없이 빈 배열을 반환한다")
    func returnsEmptyListWithoutCallingServerForEmptyQuery() async throws {
        let mock = MockSearchAutoCompletionRepository()

        let usecase = DefaultSearchAutoCompletionWordsUseCase(searchAutoCompletionRepository: mock)
        let result = try await usecase.execute(searchText: "   ")

        #expect(result.isEmpty)
        #expect(mock.searchedTexts.isEmpty)
    }

    @Test("자동완성 조회에 실패하면 에러를 던진다")
    func throwsErrorWhenSearchFails() async {
        let mock = MockSearchAutoCompletionRepository()
        mock.fetchAutoCompletionWordsResult = .failure(.networkUnavailable)

        let usecase = DefaultSearchAutoCompletionWordsUseCase(searchAutoCompletionRepository: mock)

        await #expect(throws: RepositoryError.networkUnavailable) {
            try await usecase.execute(searchText: "환생")
        }
    }
}
