//
//  LoadNovelNotificationSubscriptionsUseCase.swift
//  NotificationDomain
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain

public protocol LoadNovelNotificationSubscriptionsUseCase: Sendable {
    func execute(
        type: NovelNotificationType,
        lastSubscriptionID: SubscriptionID?,
        size: Int
    ) async throws(RepositoryError) -> PagedNovelNotificationSubscriptions
}

public final class DefaultLoadNovelNotificationSubscriptionsUseCase: LoadNovelNotificationSubscriptionsUseCase {
    private let repository: NovelNotificationRepository
    private static let defaultSize = 20

    public init(repository: NovelNotificationRepository) {
        self.repository = repository
    }

    public func execute(
        type: NovelNotificationType,
        lastSubscriptionID: SubscriptionID?,
        size: Int = 20
    ) async throws(RepositoryError) -> PagedNovelNotificationSubscriptions {
        let size = size > 0 ? size : Self.defaultSize
        return try await repository.loadSubscriptions(type: type, lastSubscriptionID: lastSubscriptionID, size: size)
    }
}
