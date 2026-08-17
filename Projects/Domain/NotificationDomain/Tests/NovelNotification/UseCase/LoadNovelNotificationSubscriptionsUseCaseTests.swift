//
//  LoadNovelNotificationSubscriptionsUseCaseTests.swift
//  NotificationDomain
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

@testable import NotificationDomain
import NotificationDomainTesting
import BaseDomain

@Suite("LoadNovelNotificationSubscriptionsUseCase")
struct LoadNovelNotificationSubscriptionsUseCaseTests {

    private func makeSubscription(id: Int = 1) -> NovelNotificationSubscription {
        NovelNotificationSubscription(
            id: SubscriptionID(id),
            novelID: NovelID(id),
            novelTitle: "테스트 작품 \(id)",
            novelThumbnailImage: URL(string: "https://image.websoso.kr/novel/\(id).jpg"),
            novelAuthor: "테스트 작가",
            registeredDateText: "2026.08.06"
        )
    }

    private func makePaged(
        count: Int = 1,
        isLoadable: Bool = true,
        nextSubscriptionID: SubscriptionID? = nil
    ) -> PagedNovelNotificationSubscriptions {
        PagedNovelNotificationSubscriptions(
            subscriptions: (1...count).map { makeSubscription(id: $0) },
            isLoadable: isLoadable,
            nextSubscriptionID: nextSubscriptionID
        )
    }

    @Test("완결·휴재복귀 타입과 lastSubscriptionID·size를 그대로 레포지토리에 전달한다")
    func loadsSubscriptionsWithParameters() async throws {
        let repo = MockNovelNotificationRepository()
        repo.loadSubscriptionsResult = .success(makePaged())

        let sut = DefaultLoadNovelNotificationSubscriptionsUseCase(repository: repo)

        let lastID = SubscriptionID(10)
        _ = try await sut.execute(type: .hiatusReturn, lastSubscriptionID: lastID, size: 30)

        #expect(repo.loadSubscriptionsCallCount == 1)
        #expect(repo.loadedType == .hiatusReturn)
        #expect(repo.loadedLastSubscriptionID == lastID)
        #expect(repo.loadedSize == 30)
    }

    @Test("size가 0 이하이면 기본 size(20)로 조회한다")
    func usesDefaultSizeWhenNonPositive() async throws {
        let repo = MockNovelNotificationRepository()
        repo.loadSubscriptionsResult = .success(makePaged())

        let sut = DefaultLoadNovelNotificationSubscriptionsUseCase(repository: repo)

        _ = try await sut.execute(type: .completion, lastSubscriptionID: nil, size: 0)
        #expect(repo.loadedSize == 20)

        _ = try await sut.execute(type: .completion, lastSubscriptionID: nil, size: -1)
        #expect(repo.loadedSize == 20)
    }

    @Test("조회 중 레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockNovelNotificationRepository()
        repo.loadSubscriptionsResult = .failure(.networkUnavailable)

        let sut = DefaultLoadNovelNotificationSubscriptionsUseCase(repository: repo)

        await #expect(throws: RepositoryError.networkUnavailable) {
            _ = try await sut.execute(type: .completion, lastSubscriptionID: nil, size: 20)
        }

        #expect(repo.loadSubscriptionsCallCount == 1)
    }
}
