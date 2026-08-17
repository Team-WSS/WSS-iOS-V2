//
//  DefaultNovelNotificationSettingService.swift
//  NotificationData
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking

struct DefaultNovelNotificationSettingService: NovelNotificationSettingService {
    private let client: NetworkingRequestable

    init(client: NetworkingRequestable) {
        self.client = client
    }

    func getNotificationSetting(novelID: Int) async throws -> NovelNotificationSettingResponse {
        let endpoint = NovelNotificationSettingEndpoint.getNotificationSetting(novelID: novelID)
        return try await client.request(endpoint, decodeTo: NovelNotificationSettingResponse.self)
    }

    func putNotificationSetting(novelID: Int, request: NovelNotificationSettingRequest) async throws {
        let endpoint = NovelNotificationSettingEndpoint.putNotificationSetting(novelID: novelID, request: request)
        _ = try await client.request(endpoint)
    }
}
