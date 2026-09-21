//
//  ClearRecentSearchWordsUseCaseTests.swift
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
struct ClearRecentSearchWordsUseCaseTests {

    @Test("최근 검색어를 전체 삭제한다")
    func clearsAllRecentSearchWords() async throws {
        let mock = MockRecentSearchRepository()

        let usecase = DefaultClearRecentSearchWordsUseCase(recentSearchRepository: mock)
        try await usecase.execute()

        #expect(mock.clearCallCount == 1)
    }

    @Test("전체 삭제에 실패하면 에러를 던진다")
    func throwsErrorWhenClearFails() async {
        let mock = MockRecentSearchRepository()
        mock.clearRecentSearchWordsResult = .failure(.unknown)

        let usecase = DefaultClearRecentSearchWordsUseCase(recentSearchRepository: mock)

        await #expect(throws: RepositoryError.unknown) {
            try await usecase.execute()
        }
    }
}
