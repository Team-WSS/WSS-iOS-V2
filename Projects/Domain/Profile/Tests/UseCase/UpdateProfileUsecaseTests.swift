//
//  UpdateProfileUsecaseTests.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import ProfileDomain
@testable import ProfileDomainTesting

@Suite("UpdateProfileUsecase")
struct UpdateProfileUsecaseTests {

    @Test("레포지토리의 updateProfile이 draft와 함께 호출된다")
    func callsUpdateProfileWithGivenDraft() async throws {
        let repo = MockProfileRepository()
        repo.updateProfileResult = .success(())
        let draft = makeProfileDraft(characterID: 5, nickname: "newNick", introduction: "새 소개글")

        let sut = DefaultUpdateProfileUsecase(profileRepository: repo)

        try await sut.execute(draft)

        #expect(repo.updateProfileCallCount == 1)
        #expect(repo.updatedDrafts.first?.characterID == 5)
        #expect(repo.updatedDrafts.first?.nickname.text == "newNick")
        #expect(repo.updatedDrafts.first?.introduction == "새 소개글")
    }

    @Test("레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockProfileRepository()
        repo.updateProfileResult = .failure(.serverUnavailable)
        let draft = makeProfileDraft()

        let sut = DefaultUpdateProfileUsecase(profileRepository: repo)

        await #expect(throws: RepositoryError.serverUnavailable) {
            try await sut.execute(draft)
        }

        #expect(repo.updateProfileCallCount == 1)
    }
}

extension UpdateProfileUsecaseTests {

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
