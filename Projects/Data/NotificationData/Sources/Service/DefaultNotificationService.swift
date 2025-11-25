//
//  DefaultNotificationService.swift
//  NotificationData
//
//  Created by YunhakLee on 11/25/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//


import Foundation
import Networking

final class DefaultNotificationService: NotificationService {
    private let client: NetworkingRequestable
    
    init(client: NetworkingRequestable) {
        self.client = client
    }
    
    // MARK: - 앱 내 알림
    
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
    
    // MARK: - Push 알림
    
    func postFCMToken(_ request: FCMTokenRequest) async throws {
        let endpoint = NotificationEndpoint.postFCMToken(request)
        _ = try await client.request(endpoint)
    }
    
    func postPushNotificationSetting(_ request: PushNotificationSettingRequest) async throws {
        let endpoint = NotificationEndpoint.postPushNotificationSetting(request)
        _ = try await client.request(endpoint)
    }
    
    func getPushNotificationSetting() async throws -> PushNotificationSettingResponse {
        let endpoint = NotificationEndpoint.getPushNotificationSetting
        return try await client.request(endpoint, decodeTo: PushNotificationSettingResponse.self)
    }
}
