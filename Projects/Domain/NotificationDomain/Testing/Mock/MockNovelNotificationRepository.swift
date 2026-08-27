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

    // MARK: - loadNotificationSetting

    public var loadedNovelID: NovelID?
    public var loadNotificationSettingCallCount = 0
    public var loadNotificationSettingResult: Result<NovelNotificationSetting, RepositoryError>?

    public func loadNotificationSetting(novelID: NovelID) async throws(RepositoryError) -> NovelNotificationSetting {
        loadNotificationSettingCallCount += 1
        loadedNovelID = novelID

        guard let loadNotificationSettingResult else {
            fatalError("loadNotificationSettingResult is not set")
        }

        switch loadNotificationSettingResult {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }

    // MARK: - updateNotificationSetting

    public var updatedNovelID: NovelID?
    public var updatedSetting: NovelNotificationSetting?
    public var updateNotificationSettingCallCount = 0
    public var updateNotificationSettingResult: Result<Void, RepositoryError>?

    public func updateNotificationSetting(
        novelID: NovelID,
        setting: NovelNotificationSetting
    ) async throws(RepositoryError) {
        updateNotificationSettingCallCount += 1
        updatedNovelID = novelID
        updatedSetting = setting

        if let updateNotificationSettingResult {
            switch updateNotificationSettingResult {
            case .success:
                return
            case .failure(let error):
                throw error
            }
        }
    }

    public init() {}
}
