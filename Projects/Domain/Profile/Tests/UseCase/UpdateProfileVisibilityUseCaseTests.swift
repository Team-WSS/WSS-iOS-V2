//
//  UpdateProfileVisibilityUseCaseTests.swift
//  ProfileDomain
//
//  Created by YunhakLee on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import ProfileDomain
import ProfileDomainTesting
import BaseDomain

@Suite("UpdateProfileVisibilityUseCase")
struct UpdateProfileVisibilityUseCaseTests {

    @Test("프로필 공개 여부를 변경할 수 있다")
    func updatesProfileVisibility() async throws {
        let repo = MockProfileRepository()
        repo.updateProfileVisibilityResult = .success(())

        let sut = DefaultUpdateProfileVisibilityUseCase(repository: repo)
        let visibility = ProfileVisibility(isPublic: false)

        try await sut.execute(visibility)

        #expect(repo.updateProfileVisibilityCallCount == 1)
        #expect(repo.updatedVisibilities == [visibility])
    }

    @Test("변경 중 레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockProfileRepository()
        repo.updateProfileVisibilityResult = .failure(.authenticationRequired)

        let sut = DefaultUpdateProfileVisibilityUseCase(repository: repo)

        await #expect(throws: RepositoryError.authenticationRequired) {
            try await sut.execute(ProfileVisibility(isPublic: true))
        }

        #expect(repo.updateProfileVisibilityCallCount == 1)
    }
}
