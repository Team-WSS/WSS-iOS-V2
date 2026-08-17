//
//  NovelNotificationSettingRepository.swift
//  NotificationDomain
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain

public protocol NovelNotificationSettingRepository {
    func loadNotificationSetting(novelID: NovelID) async throws(RepositoryError) -> NovelNotificationSetting

    /// PUT은 멱등 — `setting`의 두 값을 항상 함께 보낸다(서버가 부분 갱신을 지원하지 않음).
    func updateNotificationSetting(
        novelID: NovelID,
        setting: NovelNotificationSetting
    ) async throws(RepositoryError)
}
