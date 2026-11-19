//
//  LoadPagedNotificationsUseCaseTests.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

import BaseDomain
import NotificationDomain
import NotificationDomainTesting

@Suite("알림 목록 불러오기")
struct LoadPagedNotificationsUseCaseTests {

    @Test(
        "개수를 0 이하로 요청하면 20개씩 불러온다",
        arguments: [
            0,     // 경계
            -1     // 음수
        ]
    )
    func nonPositiveSizeLoadsTwenty(size: Int) async throws {
        let repository = MockNotificationRepository()
        repository.pagesBySize[20] = page()
        let useCase = DefaultLoadPagedNotificationsUseCase(repository: repository)

        let result = try await useCase.execute(lastNotificationID: nil, size: size)

        #expect(result == page())
    }

    @Test(
        "개수를 1 이상으로 요청하면 그 개수대로 불러온다",
        arguments: [
            1,     // 경계
            30     // 일반값
        ]
    )
    func positiveSizeLoadsAsRequested(size: Int) async throws {
        let repository = MockNotificationRepository()
        repository.pagesBySize[size] = page()
        let useCase = DefaultLoadPagedNotificationsUseCase(repository: repository)

        let result = try await useCase.execute(lastNotificationID: nil, size: size)

        #expect(result == page())
    }

    // MARK: - Helpers

    /// Stub이 그 개수에만 돌려주는 페이지 — 개수를 잘못 넘기면 빈 페이지가 와서 결과가 달라진다.
    private func page() -> PagedNotifications {
        PagedNotifications(
            items: [
                NotificationItem(
                    id: NotificationID(1),
                    iconURL: nil,
                    title: "알림",
                    body: "내용",
                    createdAtText: "2026.11.19",
                    isRead: false,
                    deeplink: nil
                )
            ],
            isLoadable: true
        )
    }
}
