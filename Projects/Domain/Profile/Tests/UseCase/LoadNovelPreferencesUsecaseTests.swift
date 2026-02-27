//
//  LoadNovelPreferencesUsecaseTests.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
import BaseDomain
@testable import ProfileDomain
@testable import ProfileDomainTesting

@Suite("LoadNovelPreferencesUsecase")
struct LoadNovelPreferencesUsecaseTests {

    @Test("작품 취향을 반환한다")
    func returnsNovelPreferences() async throws {
        let repo = MockProfileRepository()
        let expected = makeNovelPreference(attractivePoints: [.worldview, .character])
        repo.fetchNovelPreferencesResult = .success(expected)

        let sut = DefaultLoadNovelPreferencesUsecase(profileRepository: repo)

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

        let sut = DefaultLoadNovelPreferencesUsecase(profileRepository: repo)

        await #expect(throws: RepositoryError.serverUnavailable) {
            _ = try await sut.execute(.me)
        }

        #expect(repo.fetchNovelPreferencesCallCount == 1)
    }
}

extension LoadNovelPreferencesUsecaseTests {

    private func makeNovelPreference(
        attractivePoints: [AttractivePoint] = [],
        keywords: [Keyword: Int] = [:]
    ) -> NovelPreference {
        NovelPreference(attractivePoints: attractivePoints, keywords: keywords)
    }
}
