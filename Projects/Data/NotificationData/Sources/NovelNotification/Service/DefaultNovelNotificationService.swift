//
//  DefaultNovelNotificationService.swift
//  NotificationData
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking

struct DefaultNovelNotificationService: NovelNotificationService {
    private let client: NetworkingRequestable

    init(client: NetworkingRequestable) {
        self.client = client
    }

    func getSubscriptions(_ query: NovelNotificationSubscriptionsQuery) async throws -> NovelNotificationSubscriptionsResponse {
        let endpoint = NovelNotificationEndpoint.getSubscriptions(query)
        return try await client.request(endpoint, decodeTo: NovelNotificationSubscriptionsResponse.self)
    }

    func deleteSubscriptions(_ request: NovelNotificationUnsubscribeRequest) async throws {
        let endpoint = NovelNotificationEndpoint.deleteSubscriptions(request)
        _ = try await client.request(endpoint)
    }

    func getNotificationSetting(novelID: Int) async throws -> NovelNotificationSettingResponse {
        let endpoint = NovelNotificationEndpoint.getNotificationSetting(novelID: novelID)
        return try await client.request(endpoint, decodeTo: NovelNotificationSettingResponse.self)
    }

    func putNotificationSetting(novelID: Int, request: NovelNotificationSettingRequest) async throws {
        let endpoint = NovelNotificationEndpoint.putNotificationSetting(novelID: novelID, request: request)
        _ = try await client.request(endpoint)
    }
}
