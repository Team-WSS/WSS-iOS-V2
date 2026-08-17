//
//  NovelNotificationSettingService.swift
//  NotificationData
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

protocol NovelNotificationSettingService {
    func getNotificationSetting(novelID: Int) async throws -> NovelNotificationSettingResponse
    func putNotificationSetting(novelID: Int, request: NovelNotificationSettingRequest) async throws
}
