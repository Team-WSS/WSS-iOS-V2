//
//  LoadMyLibraryKeywordsUseCaseTests.swift
//  NovelDomain
//
//  Created by YunhakLee on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import NovelDomain
import NovelDomainTesting
import BaseDomain

@Suite
struct LoadMyLibraryKeywordsUseCaseTests {

    @Test("서재에 등록한 키워드 목록을 정상적으로 불러온다")
    func loadMyLibraryKeywordsSuccess() async throws {
        let mock = MockNovelRepository()
        let expected = [
            Keyword(id: KeywordID(1), name: "빙의"),
            Keyword(id: KeywordID(2), name: "후회")
        ]
        mock.fetchMyLibraryKeywordsResult = .success(expected)

        let usecase = DefaultLoadMyLibraryKeywordsUseCase(novelRepository: mock)

        let result = try await usecase.execute()

        #expect(result == expected)
        #expect(mock.fetchMyLibraryKeywordsCallCount == 1)
    }

    @Test("등록한 키워드가 없으면 빈 목록을 반환한다")
    func loadMyLibraryKeywordsEmpty() async throws {
        let mock = MockNovelRepository()
        mock.fetchMyLibraryKeywordsResult = .success([])

        let usecase = DefaultLoadMyLibraryKeywordsUseCase(novelRepository: mock)

        let result = try await usecase.execute()

        #expect(result.isEmpty)
    }

    @Test("키워드 조회에 실패하면 에러를 던진다")
    func loadMyLibraryKeywordsFailureThrows() async {
        let mock = MockNovelRepository()
        mock.fetchMyLibraryKeywordsResult = .failure(RepositoryError.serverUnavailable)

        let usecase = DefaultLoadMyLibraryKeywordsUseCase(novelRepository: mock)

        await #expect(throws: RepositoryError.serverUnavailable) {
            try await usecase.execute()
        }
    }
}
