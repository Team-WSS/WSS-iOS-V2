//
//  LoadLocalGenderAndBirthUseCaseTests.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 7/16/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import ProfileDomain
import ProfileDomainTesting
import BaseDomain

@Suite("LoadLocalGenderAndBirthUseCase")
struct LoadLocalGenderAndBirthUseCaseTests {

    private func makeAccountInfoDraft() -> AccountInfoDraft {
        AccountInfoDraft(email: nil, gender: .female, birth: try! BirthYear(1990))
    }

    @Test("userDefaults에 저장된 성별/출생연도를 조회할 수 있다")
    func loadsLocalGenderAndBirth() async throws {
        let repo = MockProfileRepository()
        let expected = makeAccountInfoDraft()
        repo.loadLocalGenderAndBirthResult = .success(expected)

        let sut = DefaultLoadLocalGenderAndBirthUseCase(repository: repo)

        let result = try await sut.execute()

        #expect(repo.loadLocalGenderAndBirthCallCount == 1)
        #expect(result == expected)
    }

    @Test("조회 중 레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockProfileRepository()
        repo.loadLocalGenderAndBirthResult = .failure(.notFound)

        let sut = DefaultLoadLocalGenderAndBirthUseCase(repository: repo)

        await #expect(throws: RepositoryError.notFound) {
            _ = try await sut.execute()
        }

        #expect(repo.loadLocalGenderAndBirthCallCount == 1)
    }
}
