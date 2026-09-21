//
//  MockNotificationRepository.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import NotificationDomain
import BaseDomain

public final class MockNotificationRepository: NotificationRepository {

    // MARK: - loadNotifications

    public var loadedLastNotificationID: NotificationID?
    public var loadedSize: Int?
    public var loadNotificationsCallCount = 0
    public var loadNotificationsResult: Result<PagedNotifications, RepositoryError>?

    public func loadNotifications(
        lastNotificationID: NotificationID?,
        size: Int
    ) async throws(RepositoryError) -> PagedNotifications {
        loadNotificationsCallCount += 1
        loadedLastNotificationID = lastNotificationID
        loadedSize = size

        guard let loadNotificationsResult else {
            fatalError("loadNotificationsResult is not set")
        }

        switch loadNotificationsResult {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }

    // MARK: - loadNotificationDetail

    public var loadedDetailID: NotificationID?
    public var loadDetailCallCount = 0
    public var loadDetailResult: Result<NotificationDetail, RepositoryError>?

    public func loadNotificationDetail(
        id: NotificationID
    ) async throws(RepositoryError) -> NotificationDetail {
        loadDetailCallCount += 1
        loadedDetailID = id

        guard let loadDetailResult else {
            fatalError("loadDetailResult is not set")
        }

        switch loadDetailResult {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }

    // MARK: - markAsRead

    public var markedIDs: [NotificationID] = []
    public var markAsReadCallCount = 0
    public var markAsReadResult: Result<Void, RepositoryError>?

    public func markAsRead(
        id: NotificationID
    ) async throws(RepositoryError) {
        markAsReadCallCount += 1
        markedIDs.append(id)

        if let markAsReadResult {
            switch markAsReadResult {
            case .success:
                return
            case .failure(let error):
                throw error
            }
        }
    }

    // MARK: - loadUnreadNotificationStatus

    public var loadUnreadStatusCallCount = 0
    public var loadUnreadStatusResult: Result<UnreadNotificationStatus, RepositoryError>?

    public func loadUnreadNotificationStatus(
    ) async throws(RepositoryError) -> UnreadNotificationStatus {
        loadUnreadStatusCallCount += 1

        guard let loadUnreadStatusResult else {
            fatalError("loadUnreadStatusResult is not set")
        }

        switch loadUnreadStatusResult {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }

    public init() {}
}
