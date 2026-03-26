//
//  DefaultNotificationService.swift
//  NotificationData
//
//  Created by YunhakLee on 11/25/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//


import Foundation
import Networking

struct DefaultNotificationService: NotificationService {
    private let client: NetworkingRequestable
    
    init(client: NetworkingRequestable) {
        self.client = client
    }

    func getNotifications(_ query: NotificationQeury) async throws -> NotificationListResponse {
        let endpoint = NotificationEndpoint.getNotifications(query)
        return try await client.request(endpoint, decodeTo: NotificationListResponse.self)
    }
    
    func getNotificationDetail(notificationId: Int) async throws -> NotificationDetailResponse {
        let endpoint = NotificationEndpoint.getNotificationDetail(notificationId: notificationId)
        return try await client.request(endpoint, decodeTo: NotificationDetailResponse.self)
    }
    
    func getNotificationUnreadStatus() async throws -> NotificationUnreadStatusResponse {
        let endpoint = NotificationEndpoint.getNotificationUnreadStatus
        return try await client.request(endpoint, decodeTo: NotificationUnreadStatusResponse.self)
    }
    
    func postNotificationRead(notificationId: Int) async throws {
        let endpoint = NotificationEndpoint.postNotificationRead(notificationId: notificationId)
        _ = try await client.request(endpoint)
    }
}
