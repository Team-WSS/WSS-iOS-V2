//
//  LoadProfileDraftUsecaseTests.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import ProfileDomain
@testable import ProfileDomainTesting

@Suite("LoadProfileDraftUsecase")
struct LoadProfileDraftUsecaseTests {

    @Test("레포지토리에서 받은 ProfileDraft를 그대로 반환한다")
    func returnsProfileDraftFromRepository() async throws {
        let repo = MockProfileRepository()
        let expected = makeProfileDraft()
        repo.loadInitialProfileResult = .success(expected)

        let sut = DefaultLoadProfileDraftUsecase(profileRepository: repo)

        let result = try await sut.execute()

        #expect(repo.loadInitialProfileCallCount == 1)
        #expect(result.characterID == expected.characterID)
        #expect(result.nickname.text == expected.nickname.text)
        #expect(result.introduction == expected.introduction)
        #expect(result.genrePreferences == expected.genrePreferences)
    }

    @Test("레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockProfileRepository()
        repo.loadInitialProfileResult = .failure(.serverUnavailable)

        let sut = DefaultLoadProfileDraftUsecase(profileRepository: repo)

        await #expect(throws: RepositoryError.serverUnavailable) {
            _ = try await sut.execute()
        }

        #expect(repo.loadInitialProfileCallCount == 1)
    }
}

extension LoadProfileDraftUsecaseTests {

    private func makeProfileDraft(
        characterID: Int = 1,
        nickname: String = "서연",
        introduction: String = "안녕하세요",
        genrePreferences: [GenrePreference] = []
    ) -> ProfileDraft {
        ProfileDraft(
            characterID: characterID,
            nickname: nickname,
            introduction: introduction,
            genrePreferences: genrePreferences
        )
    }
}
