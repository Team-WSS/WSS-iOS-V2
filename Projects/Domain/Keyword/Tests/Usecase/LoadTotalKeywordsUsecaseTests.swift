//
//  LoadTotalKeywordsUsecaseTests.swift
//  KeywordDomain
//
//  Created by Seoyeon Choi on 2/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import KeywordDomain
@testable import BaseDomain

@Suite
struct LoadTotalKeywordsUsecaseTests {

    @Test("전체 키워드 목록을 성공적으로 불러온다.")
    func loadTotalKeywordsSuccess() async throws {
        let mock = MockKeywordRepository()
        mock.fetchKeywordsResult = .success([makeKeywordGroup()])

        let usecase = DefaultFetchTotalKeywordsUsecase(keywordRepository: mock)
        let result = try await usecase.execute()

        #expect(result.count == 1)
        #expect(result.first?.name == "로맨스")
        #expect(mock.fetchKeywordsCallCount == 1)
    }

    @Test("여러 그룹의 키워드를 모두 반환한다.")
    func loadMultipleKeywordGroupsSuccess() async throws {
        let mock = MockKeywordRepository()
        mock.fetchKeywordsResult = .success([
            makeKeywordGroup(name: "로맨스"),
            makeKeywordGroup(name: "판타지"),
            makeKeywordGroup(name: "현대")
        ])

        let usecase = DefaultFetchTotalKeywordsUsecase(keywordRepository: mock)
        let result = try await usecase.execute()

        #expect(result.count == 3)
        #expect(mock.fetchKeywordsCallCount == 1)
    }

    @Test("전체 키워드 목록이 비어있어도 빈 배열을 반환한다.")
    func loadEmptyKeywordsSuccess() async throws {
        let mock = MockKeywordRepository()
        mock.fetchKeywordsResult = .success([])

        let usecase = DefaultFetchTotalKeywordsUsecase(keywordRepository: mock)
        let result = try await usecase.execute()

        #expect(result.isEmpty)
        #expect(mock.fetchKeywordsCallCount == 1)
    }

    @Test("전체 키워드 조회 실패 시 에러를 던진다.")
    func loadTotalKeywordsFailureThrows() async {
        let mock = MockKeywordRepository()
        mock.fetchKeywordsResult = .failure(MockKeywordRepository.MockError.fetchFailed)

        let usecase = DefaultFetchTotalKeywordsUsecase(keywordRepository: mock)

        await #expect(throws: MockKeywordRepository.MockError.fetchFailed) {
            try await usecase.execute()
        }

        #expect(mock.fetchKeywordsCallCount == 1)
    }
}

extension LoadTotalKeywordsUsecaseTests {
    private func makeKeywordGroup(name: String = "로맨스") -> KeywordGroup {
        KeywordGroup(
            name: name,
            profileImage: ImageWrapper(identifier: "test"),
            keywords: [
                Keyword(id: KeywordID(1), name: "이세계"),
                Keyword(id: KeywordID(2), name: "웹툰화")
            ]
        )
    }
}
