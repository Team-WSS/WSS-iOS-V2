//
//  LoadNovelNotificationSubscriptionsUseCaseTests.swift
//  NotificationDomain
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

import BaseDomain
import NotificationDomain
import NotificationDomainTesting

@Suite("작품 알림 구독 목록 불러오기")
struct LoadNovelNotificationSubscriptionsUseCaseTests {

    @Test(
        "개수를 0 이하로 요청하면 20개씩 불러온다",
        arguments: [
            0,     // 경계
            -1     // 음수
        ]
    )
    func nonPositiveSizeLoadsTwenty(size: Int) async throws {
        let repository = MockNovelNotificationRepository()
        repository.pagesBySize[20] = page()
        let useCase = DefaultLoadNovelNotificationSubscriptionsUseCase(repository: repository)

        let result = try await useCase.execute(type: .completion, lastSubscriptionID: nil, size: size)

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
        let repository = MockNovelNotificationRepository()
        repository.pagesBySize[size] = page()
        let useCase = DefaultLoadNovelNotificationSubscriptionsUseCase(repository: repository)

        let result = try await useCase.execute(type: .completion, lastSubscriptionID: nil, size: size)

        #expect(result == page())
    }

    // MARK: - Helpers

    /// Stub이 그 개수에만 돌려주는 페이지 — 개수를 잘못 넘기면 빈 페이지가 와서 결과가 달라진다.
    private func page() -> PagedNovelNotificationSubscriptions {
        PagedNovelNotificationSubscriptions(
            subscriptions: [
                NovelNotificationSubscription(
                    id: SubscriptionID(1),
                    novelID: NovelID(1),
                    novelTitle: "작품",
                    novelThumbnailImage: nil,
                    novelAuthor: "작가",
                    registeredDateText: "2026.11.19"
                )
            ],
            isLoadable: true,
            nextSubscriptionID: SubscriptionID(2)
        )
    }
}
