//
//  NovelNotificationRepository.swift
//  NotificationDomain
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain

public protocol NovelNotificationRepository {
    func loadSubscriptions(
        type: NovelNotificationType,
        lastSubscriptionID: SubscriptionID?,
        size: Int
    ) async throws(RepositoryError) -> PagedNovelNotificationSubscriptions

    /// 선택한 작품들의 구독을 한 번에 해제한다 — 구독 자체(`SubscriptionID`)가 아니라 `NovelID` 기준.
    func deleteSubscriptions(
        type: NovelNotificationType,
        novelIDs: [NovelID]
    ) async throws(RepositoryError)
}
