//
//  LoadProfileVisibilityUseCaseTests.swift
//  ProfileDomain
//
//  Created by YunhakLee on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


//
//  LoadProfileVisibilityUseCaseTests.swift
//  ProfileDomainTests
//

import Testing
import BaseDomain
@testable import ProfileDomain
@testable import ProfileDomainTesting

@Suite("LoadProfileVisibilityUseCase")
struct LoadProfileVisibilityUseCaseTests {

    @Test("프로필 공개 여부를 조회할 수 있다")
    func loadsProfileVisibility() async throws {
        let repo = MockProfileRepository()
        let expected = ProfileVisibility(isPublic: true)
        repo.loadProfileVisibilityResult = .success(expected)

        let sut = DefaultLoadProfileVisibilityUseCase(repository: repo)

        let result = try await sut.execute()

        #expect(repo.loadProfileVisibilityCallCount == 1)
        #expect(result == expected)
    }

    @Test("조회 중 레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockProfileRepository()
        repo.loadProfileVisibilityResult = .failure(.networkUnavailable)

        let sut = DefaultLoadProfileVisibilityUseCase(repository: repo)

        await #expect(throws: RepositoryError.networkUnavailable) {
            _ = try await sut.execute()
        }

        #expect(repo.loadProfileVisibilityCallCount == 1)
    }
}
