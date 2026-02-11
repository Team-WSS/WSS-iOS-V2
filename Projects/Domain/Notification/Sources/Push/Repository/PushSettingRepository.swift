//
//  PushSettingRepository.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


public protocol PushSettingRepository: Sendable {
    func loadPushPreference() async throws(RepositoryError) -> PushPreference
    func updatePushPreference(_ pref: PushPreference) async throws(RepositoryError)
    func registerDeviceToken(_ token: DevicePushToken) async throws(RepositoryError)
}