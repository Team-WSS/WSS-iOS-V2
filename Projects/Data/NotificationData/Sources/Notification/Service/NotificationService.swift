//
//  NotificationService.swift
//  NotificationData
//
//  Created by YunhakLee on 11/25/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//


import Foundation

protocol NotificationService {
    
    func getNotifications(_ query: NotificationQuery) async throws -> PagedNotificationsResponse
    func getNotificationDetail(notificationId: Int) async throws -> NotificationDetailResponse
    func getNotificationUnreadStatus() async throws -> NotificationUnreadStatusResponse
    func postNotificationRead(notificationId: Int) async throws
}
