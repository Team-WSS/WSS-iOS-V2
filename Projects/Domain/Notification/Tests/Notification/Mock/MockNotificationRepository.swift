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

final class MockNotificationRepository: NotificationRepository {

    // MARK: - loadNotifications

    var loadedLastNotificationID: NotificationID?
    var loadedSize: Int?
    var loadNotificationsCallCount = 0
    var loadNotificationsResult: Result<PagedNotifications, RepositoryError>?

    func loadNotifications(
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

    var loadedDetailID: NotificationID?
    var loadDetailCallCount = 0
    var loadDetailResult: Result<NotificationDetail, RepositoryError>?

    func loadNotificationDetail(
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

    var markedIDs: [NotificationID] = []
    var markAsReadCallCount = 0
    var markAsReadResult: Result<Void, RepositoryError>?

    func markAsRead(
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

    var loadUnreadStatusCallCount = 0
    var loadUnreadStatusResult: Result<UnreadNotificationStatus, RepositoryError>?

    func loadUnreadNotificationStatus(
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
}
