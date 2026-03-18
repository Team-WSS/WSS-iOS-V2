//
//  UnblockUserUseCaseTests.swift
//  SocialDomain
//
//  Created by YunhakLee on 2/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import SocialDomain
import SocialDomainTesting
import BaseDomain

@Suite("UnblockUserUseCase")
struct UnblockUserUseCaseTests {

    @Test("주어진 차단 ID로 차단 해제를 할 수 있다")
    func unblocksUser() async throws {
        let repo = MockSocialRepository()
        repo.unblockUserResult = .success(())

        let sut = DefaultUnblockUserUseCase(repository: repo)

        let blockID = BlockID(10)
        try await sut.execute(id: blockID)

        #expect(repo.unblockUserCallCount == 1)
        #expect(repo.unblockedBlockIDs == [blockID])
    }

    @Test("차단 해제 중 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockSocialRepository()
        repo.unblockUserResult = .failure(.notFound)

        let sut = DefaultUnblockUserUseCase(repository: repo)

        await #expect(throws: RepositoryError.notFound) {
            try await sut.execute(id: BlockID(10))
        }

        #expect(repo.unblockUserCallCount == 1)
    }
}
