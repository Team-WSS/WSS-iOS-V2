//
//  MockNovelNotificationRepository.swift
//  NotificationDomain
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import NotificationDomain
import BaseDomain

public final class MockNovelNotificationRepository: NovelNotificationRepository {

    // MARK: - loadSubscriptions

    public var loadedType: NovelNotificationType?
    public var loadedLastSubscriptionID: SubscriptionID?
    public var loadedSize: Int?
    public var loadSubscriptionsCallCount = 0
    public var loadSubscriptionsResult: Result<PagedNovelNotificationSubscriptions, RepositoryError>?

    public func loadSubscriptions(
        type: NovelNotificationType,
        lastSubscriptionID: SubscriptionID?,
        size: Int
    ) async throws(RepositoryError) -> PagedNovelNotificationSubscriptions {
        loadSubscriptionsCallCount += 1
        loadedType = type
        loadedLastSubscriptionID = lastSubscriptionID
        loadedSize = size

        guard let loadSubscriptionsResult else {
            fatalError("loadSubscriptionsResult is not set")
        }

        switch loadSubscriptionsResult {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }

    // MARK: - deleteSubscriptions

    public var deletedType: NovelNotificationType?
    public var deletedNovelIDs: [NovelID]?
    public var deleteSubscriptionsCallCount = 0
    public var deleteSubscriptionsResult: Result<Void, RepositoryError>?

    public func deleteSubscriptions(
        type: NovelNotificationType,
        novelIDs: [NovelID]
    ) async throws(RepositoryError) {
        deleteSubscriptionsCallCount += 1
        deletedType = type
        deletedNovelIDs = novelIDs

        if let deleteSubscriptionsResult {
            switch deleteSubscriptionsResult {
            case .success:
                return
            case .failure(let error):
                throw error
            }
        }
    }

    public init() {}
}
