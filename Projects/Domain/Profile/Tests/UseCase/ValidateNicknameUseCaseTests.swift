//
//  ValidateNicknameUseCaseTests.swift
//  ProfileDomain
//
//  Created by YunhakLee on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Testing

@testable import ProfileDomain
import ProfileDomainTesting
import BaseDomain

@Suite("ValidateNicknameUseCase")
struct ValidateNicknameUseCaseTests {

    @Test("닉네임 중복 여부를 조회할 수 있다")
    func returnsDuplicationStatus() async throws {
        let repo = MockProfileRepository()
        repo.validateNicknameResult = .success(true)

        let sut = DefaultValidateNicknameUseCase(repository: repo)

        let isDuplicated = try await sut.execute("갑갑")

        #expect(repo.validateNicknameCallCount == 1)
        #expect(repo.validatedNicknames == ["갑갑"])
        #expect(isDuplicated == true)
    }

    @Test("조회 중 레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockProfileRepository()
        repo.validateNicknameResult = .failure(.serverUnavailable)

        let sut = DefaultValidateNicknameUseCase(repository: repo)

        await #expect(throws: RepositoryError.serverUnavailable) {
            _ = try await sut.execute("갑갑")
        }

        #expect(repo.validateNicknameCallCount == 1)
    }
}
