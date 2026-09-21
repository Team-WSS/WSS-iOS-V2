//
//  LoadGenrePreferencesUseCaseTests.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import ProfileDomain
import ProfileDomainTesting
import BaseDomain

@Suite("LoadGenrePreferencesUseCase")
struct LoadGenrePreferencesUseCaseTests {

    @Test("장르 취향 목록을 반환한다")
    func returnsGenrePreferences() async throws {
        let repo = MockProfileRepository()
        let expected = [makeGenre(genre: .romance), makeGenre(genre: .fantasy)]
        repo.fetchGenrePreferencesResult = .success(expected)

        let sut = DefaultLoadGenrePreferencesUseCase(profileRepository: repo)

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

        let sut = DefaultLoadGenrePreferencesUseCase(profileRepository: repo)

        let result = try await sut.execute(.me)

        #expect(result.isEmpty)
    }

    @Test("레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockProfileRepository()
        repo.fetchGenrePreferencesResult = .failure(.serverUnavailable)

        let sut = DefaultLoadGenrePreferencesUseCase(profileRepository: repo)

        await #expect(throws: RepositoryError.serverUnavailable) {
            _ = try await sut.execute(.me)
        }

        #expect(repo.fetchGenrePreferencesCallCount == 1)
    }
}

extension LoadGenrePreferencesUseCaseTests {

    private func makeGenre(genre: NovelGenre = .romance) -> GenrePreference {
        GenrePreference(genre: genre, count: 0)
    }
}
