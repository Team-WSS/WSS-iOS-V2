//
//  SyncUserBasicInfoUseCaseTests.swift
//  ProfileDomain
//
//  Created by YunhakLee on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


//
//  SyncUserBasicInfoUseCaseTests.swift
//  ProfileDomainTests
//

import Testing
import BaseDomain
@testable import ProfileDomain
@testable import ProfileDomainTesting

@Suite("SyncUserBasicInfoUseCase")
struct SyncUserBasicInfoUseCaseTests {

    @Test("유저 기본 정보를 동기화할 수 있다")
    func syncsUserBasicInfo() async throws {
        let repo = MockProfileRepository()
        repo.syncUserBasicInfoResult = .success(())

        let sut = DefaultSyncUserBasicInfoUseCase(repository: repo)

        try await sut.execute()

        #expect(repo.syncUserBasicInfoCallCount == 1)
    }

    @Test("동기화 중 레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockProfileRepository()
        repo.syncUserBasicInfoResult = .failure(.networkUnavailable)

        let sut = DefaultSyncUserBasicInfoUseCase(repository: repo)

        await #expect(throws: RepositoryError.networkUnavailable) {
            try await sut.execute()
        }

        #expect(repo.syncUserBasicInfoCallCount == 1)
    }
}
