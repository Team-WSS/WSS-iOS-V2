//
//  RemoveRecentSearchWordUseCaseTests.swift
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
struct RemoveRecentSearchWordUseCaseTests {

    @Test("최근 검색어를 제거한다")
    func removesRecentSearchWord() async throws {
        let mock = MockRecentSearchRepository()
        let word = makeRecentSearchWord(id: 1, title: "환생물")

        let usecase = DefaultRemoveRecentSearchWordUseCase(recentSearchRepository: mock)
        try await usecase.execute(word: word)

        #expect(mock.removedWords.count == 1)
        #expect(mock.removedWords.first?.title == "환생물")
    }

    @Test("제거에 실패하면 에러를 던진다")
    func throwsErrorWhenRemoveFails() async {
        let mock = MockRecentSearchRepository()
        mock.removeRecentSearchWordResult = .failure(.unknown)

        let usecase = DefaultRemoveRecentSearchWordUseCase(recentSearchRepository: mock)

        await #expect(throws: RepositoryError.unknown) {
            try await usecase.execute(word: makeRecentSearchWord(id: 1, title: "환생물"))
        }
    }
}

extension RemoveRecentSearchWordUseCaseTests {
    private func makeRecentSearchWord(id: Int, title: String) -> RecentSearchWord {
        RecentSearchWord(id: SearchWordID(id), title: title)
    }
}
