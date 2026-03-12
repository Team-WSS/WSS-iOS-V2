//
//  MarkNotificationAsReadUseCaseTests.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Testing

@testable import NotificationDomain
import NotificationDomainTesting
import BaseDomain

@Suite("MarkNotificationAsReadUseCase")
struct MarkNotificationAsReadUseCaseTests {

    @Test("주어진 알림 ID를 읽음 처리한다")
    func marksAsReadSuccessfully() async throws {
        let repo = MockNotificationRepository()
        repo.markAsReadResult = .success(())

        let sut = DefaultMarkNotificationAsReadUseCase(repository: repo)

        let id = NotificationID(7)
        try await sut.execute(id: id)

        #expect(repo.markAsReadCallCount == 1)
        #expect(repo.markedIDs == [id])
    }

    @Test("읽음 처리 중 레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockNotificationRepository()
        repo.markAsReadResult = .failure(.authenticationRequired)

        let sut = DefaultMarkNotificationAsReadUseCase(repository: repo)

        await #expect(throws: RepositoryError.authenticationRequired) {
            try await sut.execute(id: NotificationID(7))
        }

        #expect(repo.markAsReadCallCount == 1)
    }
}
