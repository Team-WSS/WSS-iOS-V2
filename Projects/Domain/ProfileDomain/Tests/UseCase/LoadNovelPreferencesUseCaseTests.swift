//
//  LoadNovelPreferencesUseCaseTests.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import ProfileDomain
import ProfileDomainTesting
import BaseDomain

@Suite("LoadNovelPreferencesUseCase")
struct LoadNovelPreferencesUseCaseTests {

    @Test("작품 취향을 반환한다")
    func returnsNovelPreferences() async throws {
        let repo = MockProfileRepository()
        let expected = makeNovelPreference(attractivePoints: [.worldview, .character])
        repo.fetchNovelPreferencesResult = .success(expected)

        let sut = DefaultLoadNovelPreferencesUseCase(
            profileRepository: repo,
            keywordRepository: StubKeywordRepository()
        )

        let result = try await sut.execute(.me)

        #expect(repo.fetchNovelPreferencesCallCount == 1)
        guard case .me = repo.fetchedNovelPreferenceTargets.first else {
            Issue.record(".me 타겟이 전달되어야 한다")
            return
        }
        #expect(result.attractivePoints == expected.attractivePoints)
        #expect(result.keywords == expected.keywords)
    }

    @Test("레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockProfileRepository()
        repo.fetchNovelPreferencesResult = .failure(.serverUnavailable)

        let sut = DefaultLoadNovelPreferencesUseCase(
            profileRepository: repo,
            keywordRepository: StubKeywordRepository()
        )

        await #expect(throws: RepositoryError.serverUnavailable) {
            _ = try await sut.execute(.me)
        }

        #expect(repo.fetchNovelPreferencesCallCount == 1)
    }
}

private final class StubKeywordRepository: KeywordRepository {
    func fetchKeywords() async throws(RepositoryError) -> [KeywordGroup] { [] }
    func searchKeywords(_ query: String) async throws(RepositoryError) -> [Keyword] { [] }
    func syncKeywords() async {}
}

extension LoadNovelPreferencesUseCaseTests {

    private func makeNovelPreference(
        attractivePoints: [AttractivePoint] = [],
        keywords: [Keyword: Int] = [:]
    ) -> NovelPreference {
        NovelPreference(attractivePoints: attractivePoints, keywords: keywords)
    }
}
