//
//  RegisterProfileUseCaseTests.swift
//  ProfileDomain
//
//  Created by YunhakLee on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import ProfileDomain
import ProfileDomainTesting
import BaseDomain

@Suite("RegisterProfileUseCase")
struct RegisterProfileUseCaseTests {

    private func makeProfileRegistration() -> ProfileRegistration {
        // ✅ 프로젝트 타입에 맞게 여기만 조정하면 됨
        ProfileRegistration(
            nickname: "밝보",
            gender: .male,
            birthYear: try! BirthYear(2002),
            genrePreferences: [.romance, .wuxia]
        )
    }

    @Test("프로필을 최초 등록할 수 있다")
    func registersProfile() async throws {
        let repo = MockProfileRepository()
        repo.registerProfileResult = .success(())

        let sut = DefaultRegisterProfileUseCase(repository: repo)
        let profile = makeProfileRegistration()

        try await sut.execute(profile)

        #expect(repo.registerProfileCallCount == 1)
        #expect(repo.registeredProfiles == [profile])
    }

    @Test("등록 중 레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockProfileRepository()
        repo.registerProfileResult = .failure(.authenticationRequired)

        let sut = DefaultRegisterProfileUseCase(repository: repo)

        await #expect(throws: RepositoryError.authenticationRequired) {
            try await sut.execute(makeProfileRegistration())
        }

        #expect(repo.registerProfileCallCount == 1)
    }
}
