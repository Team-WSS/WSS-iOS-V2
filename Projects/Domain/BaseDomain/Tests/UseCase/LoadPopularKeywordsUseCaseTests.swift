//
//  LoadPopularKeywordsUseCaseTests.swift
//  BaseDomain
//
//  Created by Seoyeon Choi on 7/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import BaseDomain
import BaseDomainTesting

@Suite
struct LoadPopularKeywordsUseCaseTests {

    @Test("실시간 인기 키워드를 성공적으로 불러온다")
    func loadsPopularKeywordsSuccessfully() async throws {
        let mock = MockKeywordRepository()
        mock.fetchPopularKeywordsResult = .success(makePopularKeywords(names: ["이세계", "회귀", "환생"]))

        let usecase = DefaultLoadPopularKeywordsUseCase(keywordRepository: mock)
        let result = try await usecase.execute()

        #expect(result.keywords.count == 3)
        #expect(result.keywords.first?.name == "이세계")
        #expect(mock.fetchPopularKeywordsCallCount == 1)
    }

    @Test("인기 키워드가 없어도 정상적으로 반환한다")
    func returnsEmptyPopularKeywordsNormally() async throws {
        let mock = MockKeywordRepository()
        mock.fetchPopularKeywordsResult = .success(makePopularKeywords(names: []))

        let usecase = DefaultLoadPopularKeywordsUseCase(keywordRepository: mock)
        let result = try await usecase.execute()

        #expect(result.keywords.isEmpty)
    }

    @Test("인기 키워드 조회에 실패하면 에러를 던진다")
    func throwsErrorWhenLoadPopularKeywordsFails() async {
        let mock = MockKeywordRepository()
        mock.fetchPopularKeywordsResult = .failure(.networkUnavailable)

        let usecase = DefaultLoadPopularKeywordsUseCase(keywordRepository: mock)

        await #expect(throws: RepositoryError.networkUnavailable) {
            try await usecase.execute()
        }

        #expect(mock.fetchPopularKeywordsCallCount == 1)
    }
}

extension LoadPopularKeywordsUseCaseTests {
    private func makePopularKeywords(names: [String]) -> PopularKeywords {
        PopularKeywords(
            keywords: names.enumerated().map { index, name in
                Keyword(id: KeywordID(index + 1), name: name)
            }
        )
    }
}
