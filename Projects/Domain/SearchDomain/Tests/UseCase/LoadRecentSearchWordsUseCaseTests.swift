//
//  LoadRecentSearchWordsUseCaseTests.swift
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
struct LoadRecentSearchWordsUseCaseTests {

    @Test("최근 검색어를 성공적으로 불러온다")
    func loadsRecentSearchWordsSuccessfully() async throws {
        let mock = MockRecentSearchRepository()
        mock.fetchRecentSearchWordsResult = .success([
            makeRecentSearchWord(id: 1, title: "환생물"),
            makeRecentSearchWord(id: 2, title: "회귀물")
        ])

        let usecase = DefaultLoadRecentSearchWordsUseCase(recentSearchRepository: mock)
        let result = try await usecase.execute()

        #expect(result.count == 2)
        #expect(result.first?.title == "환생물")
    }

    @Test("최근 검색어가 없으면 빈 배열을 반환한다")
    func returnsEmptyListWhenNoRecentSearchWords() async throws {
        let mock = MockRecentSearchRepository()
        mock.fetchRecentSearchWordsResult = .success([])

        let usecase = DefaultLoadRecentSearchWordsUseCase(recentSearchRepository: mock)
        let result = try await usecase.execute()

        #expect(result.isEmpty)
    }

    @Test("최근 검색어 조회에 실패하면 에러를 던진다")
    func throwsErrorWhenLoadFails() async {
        let mock = MockRecentSearchRepository()
        mock.fetchRecentSearchWordsResult = .failure(.networkUnavailable)

        let usecase = DefaultLoadRecentSearchWordsUseCase(recentSearchRepository: mock)

        await #expect(throws: RepositoryError.networkUnavailable) {
            try await usecase.execute()
        }
    }
}

extension LoadRecentSearchWordsUseCaseTests {
    private func makeRecentSearchWord(id: Int, title: String) -> RecentSearchWord {
        RecentSearchWord(id: SearchWordID(id), title: title)
    }
}
