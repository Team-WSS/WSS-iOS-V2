//
//  NotificationService.swift
//  NotificationData
//
//  Created by YunhakLee on 11/25/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//


import Foundation

protocol NotificationService {
    
    // MARK: - 앱 내 알림
    
    func getNotifications(_ query: NotificationQeury) async throws -> NotificationListResponse
    func getNotificationDetail(notificationId: Int) async throws -> NotificationDetailResponse
    func getNotificationUnreadStatus() async throws -> NotificationUnreadStatusResponse
    func postNotificationRead(notificationId: Int) async throws
    
    // MARK: - Push 알림
    
    func postFCMToken(_ request: FCMTokenRequest) async throws
    func postPushNotificationSetting(_ request: PushNotificationSettingRequest) async throws
    func getPushNotificationSetting() async throws -> PushNotificationSettingResponse
}
