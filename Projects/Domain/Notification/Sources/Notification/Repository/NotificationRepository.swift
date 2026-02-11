//
//  NotificationRepository.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


public protocol NotificationRepository: Sendable {
    func loadNotifications(
        lastNotificationID: NotificationID?
    ) async throws(RepositoryError) -> PagedNotifications

    func loadNotificationDetail(
        id: NotificationID
    ) async throws(RepositoryError) -> NotificationItem

    func markAsRead(
        id: NotificationID
    ) async throws(RepositoryError)
}
