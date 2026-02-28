//
//  BlockUserUseCaseTests.swift
//  SocialDomain
//
//  Created by YunhakLee on 2/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Testing
@testable import SocialDomain
import BaseDomain
@testable import SocialDomainTesting

@Suite("BlockUserUseCase")
struct BlockUserUseCaseTests {

    @Test("주어진 유저를 차단할 수 있다")
    func blocksUser() async throws {
        let repo = MockSocialRepository()
        repo.blockUserResult = .success(())

        let sut = DefaultBlockUserUseCase(repository: repo)

        let userID = UserID(1)
        try await sut.execute(id: userID)

        #expect(repo.blockUserCallCount == 1)
        #expect(repo.blockedUserIDs == [userID])
    }

    @Test("유저 차단 중 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockSocialRepository()
        repo.blockUserResult = .failure(.notFound)

        let sut = DefaultBlockUserUseCase(repository: repo)

        await #expect(throws: RepositoryError.notFound) {
            try await sut.execute(id: UserID(1))
        }

        #expect(repo.blockUserCallCount == 1)
    }
}
