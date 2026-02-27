//
//  LoadGenrePreferencesUsecaseTests.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import ProfileDomain
@testable import ProfileDomainTesting

@Suite("LoadGenrePreferencesUsecase")
struct LoadGenrePreferencesUsecaseTests {

    @Test("장르 취향 목록을 반환한다")
    func returnsGenrePreferences() async throws {
        let repo = MockProfileRepository()
        let expected = [makeGenre(name: "로맨스"), makeGenre(name: "판타지")]
        repo.fetchGenrePreferencesResult = .success(expected)

        let sut = DefaultLoadGenrePreferencesUsecase(profileRepository: repo)

        let result = try await sut.execute(.me)

        #expect(repo.fetchGenrePreferencesCallCount == 1)
        guard case .me = repo.fetchedGenrePreferenceTargets.first else {
            Issue.record(".me 타겟이 전달되어야 한다")
            return
        }
        #expect(result == expected)
    }

    @Test("장르 취향이 없으면 빈 배열을 반환한다")
    func returnsEmptyWhenNoGenrePreferences() async throws {
        let repo = MockProfileRepository()
        repo.fetchGenrePreferencesResult = .success([])

        let sut = DefaultLoadGenrePreferencesUsecase(profileRepository: repo)

        let result = try await sut.execute(.me)

        #expect(result.isEmpty)
    }

    @Test("레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockProfileRepository()
        repo.fetchGenrePreferencesResult = .failure(.serverUnavailable)

        let sut = DefaultLoadGenrePreferencesUsecase(profileRepository: repo)

        await #expect(throws: RepositoryError.serverUnavailable) {
            _ = try await sut.execute(.me)
        }

        #expect(repo.fetchGenrePreferencesCallCount == 1)
    }
}

extension LoadGenrePreferencesUsecaseTests {

    private func makeGenre(name: String = "로맨스") -> GenrePreference {
        GenrePreference(name: name, image: nil, count: 0)
    }
}
