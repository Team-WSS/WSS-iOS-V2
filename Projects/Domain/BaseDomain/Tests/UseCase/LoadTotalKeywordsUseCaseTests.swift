//
//  LoadTotalKeywordsUseCaseTests.swift
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
struct LoadTotalKeywordsUseCaseTests {

    @Test("전체 키워드 목록을 성공적으로 불러온다.")
    func loadTotalKeywordsSuccess() async throws {
        let mock = MockKeywordRepository()
        mock.fetchKeywordsResult = .success([makeKeywordGroup()])

        let usecase = DefaultFetchTotalKeywordsUseCase(keywordRepository: mock)
        let result = try await usecase.execute()

        #expect(result.count == 1)
        #expect(result.first?.category == .worldview)
        #expect(mock.fetchKeywordsCallCount == 1)
    }

    @Test("여러 그룹의 키워드를 모두 반환한다.")
    func loadMultipleKeywordGroupsSuccess() async throws {
        let mock = MockKeywordRepository()
        mock.fetchKeywordsResult = .success([
            makeKeywordGroup(category: .worldview),
            makeKeywordGroup(category: .material),
            makeKeywordGroup(category: .character)
        ])

        let usecase = DefaultFetchTotalKeywordsUseCase(keywordRepository: mock)
        let result = try await usecase.execute()

        #expect(result.count == 3)
        #expect(mock.fetchKeywordsCallCount == 1)
    }

    @Test("전체 키워드 목록이 비어있어도 빈 배열을 반환한다.")
    func loadEmptyKeywordsSuccess() async throws {
        let mock = MockKeywordRepository()
        mock.fetchKeywordsResult = .success([])

        let usecase = DefaultFetchTotalKeywordsUseCase(keywordRepository: mock)
        let result = try await usecase.execute()

        #expect(result.isEmpty)
        #expect(mock.fetchKeywordsCallCount == 1)
    }

    @Test("전체 키워드 조회가 동기화 후 재조회에도 계속 실패하면 에러를 던진다.")
    func loadTotalKeywordsFailureThrows() async {
        let mock = MockKeywordRepository()
        mock.fetchKeywordsResult = .failure(RepositoryError.unknown)

        let usecase = DefaultFetchTotalKeywordsUseCase(keywordRepository: mock)

        await #expect(throws: RepositoryError.unknown) {
            try await usecase.execute()
        }

        // 최초 조회 실패 → 동기화 1회 → 재조회까지 시도한 뒤에도 실패하면 그 에러를 던진다.
        #expect(mock.fetchKeywordsCallCount == 2)
        #expect(mock.syncKeywordsCallCount == 1)
    }

    @Test("로컬 캐시가 비어있으면 동기화 후 재조회로 복구한다.")
    func loadTotalKeywordsRecoversAfterSyncOnCacheMiss() async throws {
        let mock = MockKeywordRepository()
        mock.fetchKeywordsResults = [
            .failure(.unknown),
            .success([makeKeywordGroup(category: .vibe)])
        ]

        let usecase = DefaultFetchTotalKeywordsUseCase(keywordRepository: mock)
        let result = try await usecase.execute()

        #expect(result.count == 1)
        #expect(result.first?.category == .vibe)
        #expect(mock.fetchKeywordsCallCount == 2)
        #expect(mock.syncKeywordsCallCount == 1)
    }
}

extension LoadTotalKeywordsUseCaseTests {
    private func makeKeywordGroup(category: KeywordCategory = .worldview) -> KeywordGroup {
        KeywordGroup(
            category: category,
            keywords: [
                Keyword(id: KeywordID(1), name: "이세계"),
                Keyword(id: KeywordID(2), name: "웹툰화")
            ]
        )
    }
}
