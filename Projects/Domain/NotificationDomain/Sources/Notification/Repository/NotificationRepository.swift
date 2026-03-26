//
//  NotificationRepository.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain

public protocol NotificationRepository {
    func loadNotifications(
        lastNotificationID: NotificationID?,
        size: Int
    ) async throws(RepositoryError) -> PagedNotifications

    func loadNotificationDetail(
        id: NotificationID
    ) async throws(RepositoryError) -> NotificationDetail

    func markAsRead(
        id: NotificationID
    ) async throws(RepositoryError)
    
    func loadUnreadNotificationStatus(
    ) async throws(RepositoryError) -> UnreadNotificationStatus
}
