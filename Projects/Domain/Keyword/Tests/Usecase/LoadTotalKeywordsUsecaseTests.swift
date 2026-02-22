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

//TODO: testing tags 붙이기
@Suite
struct LoadTotalKeywordsUsecaseTests {

    @Test("전체 키워드를 성공적으로 불러온다.")
    func loadTotalKeywordsSuccess() async throws {
        let mock = MockKeywordRepository()

        let expected = [
            KeywordGroup(
                name: "로맨스",
                profileImage: ImageWrapper(identifier: "test"),
                keywords: [
                    Keyword(id: KeywordID(1), name: "이세계"),
                    Keyword(id: KeywordID(2), name: "웹툰화")
                ]
            )
        ]

        mock.fetchKeywordsResult = .success(expected)

        let result = try await mock.fetchKeywords()

        #expect(result.count == 1)
        #expect(result.first?.name == "로맨스")
        #expect(mock.fetchKeywordsCallCount == 1)
    }

    @Test("전체 키워드 조회 실패 시 에러를 던진다.")
    func loadTotalKeywordsFailureThrows() async {
        let mock = MockKeywordRepository()

        //TODO: Repository Error로 수정
        enum TestError: Error { case dummy }

        mock.fetchKeywordsResult = .failure(TestError.dummy)

        await #expect(throws: TestError.dummy) {
            try await mock.fetchKeywords()
        }

        #expect(mock.fetchKeywordsCallCount == 1)
    }
}
