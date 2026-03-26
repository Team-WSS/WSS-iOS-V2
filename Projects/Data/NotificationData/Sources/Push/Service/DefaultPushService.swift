//
//  DefaultPushService.swift
//  NotificationData
//
//  Created by YunhakLee on 11/25/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//


import Foundation
import Networking

struct DefaultPushService: PushService {
    private let client: NetworkingRequestable
    
    init(client: NetworkingRequestable) {
        self.client = client
    }
    
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
