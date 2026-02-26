//
//  LoadBlockedUsersUseCaseTests.swift
//  SocialDomain
//
//  Created by YunhakLee on 2/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


//
//  LoadBlockedUsersUseCaseTests.swift
//  SocialDomainTests
//

import Testing
@testable import SocialDomain
import BaseDomain
@testable import SocialDomainTesting

@Suite("LoadBlockedUsersUseCase")
struct LoadBlockedUsersUseCaseTests {

    @Test("차단한 유저 목록을 조회할 수 있다")
    func loadsBlockedUsers() async throws {
        let repo = MockSocialRepository()
        repo.loadBlockedUsersResult = .success([])

        let sut = DefaultLoadBlockedUsersUseCase(repository: repo)

        let result = try await sut.execute()

        #expect(repo.loadBlockedUsersCallCount == 1)
        #expect(result == [])
    }

    @Test("차단 목록 조회 중 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockSocialRepository()
        repo.loadBlockedUsersResult = .failure(.authenticationRequired)

        let sut = DefaultLoadBlockedUsersUseCase(repository: repo)

        await #expect(throws: RepositoryError.authenticationRequired) {
            _ = try await sut.execute()
        }

        #expect(repo.loadBlockedUsersCallCount == 1)
    }
}
