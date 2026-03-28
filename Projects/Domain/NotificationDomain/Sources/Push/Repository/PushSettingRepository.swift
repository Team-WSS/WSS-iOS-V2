//
//  PushSettingRepository.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain

public protocol PushSettingRepository {
    func loadPushPreference() async throws(RepositoryError) -> PushPreference
    func updatePushPreference(_ preference: PushPreference) async throws(RepositoryError)
    func registerDeviceToken(_ token: DevicePushToken) async throws(RepositoryError)
}
