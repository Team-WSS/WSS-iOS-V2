//
//  LoadProfileUseCaseTests.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
import BaseDomain
@testable import ProfileDomain
@testable import ProfileDomainTesting

@Suite("LoadProfileUseCase")
struct LoadProfileUseCaseTests {

    @Test(".me 타겟으로 프로필을 조회할 수 있다")
    func loadsProfileWithMeTarget() async throws {
        let repo = MockProfileRepository()
        let expected = makeProfile()
        repo.fetchUserProfileResult = .success(expected)

        let sut = DefaultLoadProfileUseCase(profileRepository: repo)

        let result = try await sut.execute(target: .me)

        #expect(repo.fetchUserProfileCallCount == 1)
        guard case .me = repo.fetchedUserProfileTargets.first else {
            Issue.record(".me 타겟이 전달되어야 한다")
            return
        }
        #expect(result.nickname == expected.nickname)
        #expect(result.introduction == expected.introduction)
        #expect(result.isPublic == expected.isPublic)
    }

    @Test(".user 타겟으로 다른 유저의 프로필을 조회할 수 있다")
    func loadsProfileWithUserTarget() async throws {
        let repo = MockProfileRepository()
        repo.fetchUserProfileResult = .success(makeProfile(nickname: "다른유저"))

        let sut = DefaultLoadProfileUseCase(profileRepository: repo)

        _ = try await sut.execute(target: .user(UserID(42)))

        #expect(repo.fetchUserProfileCallCount == 1)
        guard case .user(let id) = repo.fetchedUserProfileTargets.first else {
            Issue.record(".user 타겟이 전달되어야 한다")
            return
        }
        #expect(id == UserID(42))
    }

    @Test("레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockProfileRepository()
        repo.fetchUserProfileResult = .failure(.serverUnavailable)

        let sut = DefaultLoadProfileUseCase(profileRepository: repo)

        await #expect(throws: RepositoryError.serverUnavailable) {
            _ = try await sut.execute(target: .me)
        }

        #expect(repo.fetchUserProfileCallCount == 1)
    }
}

extension LoadProfileUseCaseTests {

    private func makeProfile(
        nickname: String = "서연",
        introduction: String = "안녕하세요",
        isPublic: Bool = true
    ) -> Profile {
        Profile(
            nickname: nickname,
            introduction: introduction,
            characterImage: nil,
            isPublic: isPublic,
            genrePreferences: []
        )
    }
}
