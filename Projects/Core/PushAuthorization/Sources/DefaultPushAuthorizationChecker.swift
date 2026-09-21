//
//  DefaultPushAuthorizationChecker.swift
//  PushAuthorization
//
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import UserNotifications

public struct DefaultPushAuthorizationChecker: PushAuthorizationChecker {

    public init() {}

    public func authorizationStatus() async -> PushAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            // 새 케이스가 추가돼도 앱을 깨뜨리지 않도록 "아직 모름"으로 보수적으로 처리한다.
            return .notDetermined
        }
    }

    public func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }
}
