//
//  LoadUnreadNotificationStatusUseCaseTests.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import NotificationDomain
import NotificationDomainTesting
import BaseDomain

@Suite("LoadUnreadNotificationStatusUseCase")
struct LoadUnreadNotificationStatusUseCaseTests {

    @Test("읽지 않은 알림 존재 여부를 조회한다")
    func loadsUnreadStatusSuccessfully() async throws {
        let repo = MockNotificationRepository()
        let expected = UnreadNotificationStatus(hasUnreadNotifications: true)
        repo.loadUnreadStatusResult = .success(expected)

        let sut = DefaultLoadUnreadNotificationStatusUseCase(repository: repo)

        let result = try await sut.execute()

        #expect(repo.loadUnreadStatusCallCount == 1)
        #expect(result == expected)
    }

    @Test("조회 중 레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockNotificationRepository()
        repo.loadUnreadStatusResult = .failure(.unknown)

        let sut = DefaultLoadUnreadNotificationStatusUseCase(repository: repo)

        await #expect(throws: RepositoryError.self) {
            _ = try await sut.execute()
        }

        #expect(repo.loadUnreadStatusCallCount == 1)
    }
}
