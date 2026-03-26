//
//  PushService.swift
//  NotificationData
//
//  Created by YunhakLee on 11/25/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//


import Foundation

protocol PushService {
    
    func postFCMToken(_ request: FCMTokenRequest) async throws
    func postPushNotificationSetting(_ request: PushNotificationSettingRequest) async throws
    func getPushNotificationSetting() async throws -> PushNotificationSettingResponse
}
