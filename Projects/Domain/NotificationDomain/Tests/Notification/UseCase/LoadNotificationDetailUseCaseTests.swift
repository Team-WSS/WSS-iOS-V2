//
//  LoadNotificationDetailUseCaseTests.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import NotificationDomain
import NotificationDomainTesting
import BaseDomain

@Suite("LoadNotificationDetailUseCase")
struct LoadNotificationDetailUseCaseTests {

    private func makeDetail() -> NotificationDetail {
        return NotificationDetail(
            title: "notificationTitle",
            createdAtText: "2025.02.21",
            body: "테스트 상세입니다.")
    }

    @Test("주어진 알림 ID로 알림 상세를 조회한다")
    func loadsDetailSuccessfully() async throws {
        let repo = MockNotificationRepository()
        let expected = makeDetail()
        repo.loadDetailResult = .success(expected)

        let sut = DefaultLoadNotificationDetailUseCase(repository: repo)

        let id = NotificationID(3)
        let result = try await sut.execute(id: id)

        #expect(repo.loadDetailCallCount == 1)
        #expect(repo.loadedDetailID == id)
        #expect(result == expected)
    }

    @Test("조회 중 레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockNotificationRepository()
        repo.loadDetailResult = .failure(.serverUnavailable)

        let sut = DefaultLoadNotificationDetailUseCase(repository: repo)

        await #expect(throws: RepositoryError.serverUnavailable) {
            _ = try await sut.execute(id: NotificationID(3))
        }

        #expect(repo.loadDetailCallCount == 1)
    }
}
