//
//  NovelNotificationRepository.swift
//  NotificationDomain
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain

public protocol NovelNotificationRepository: Sendable {
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

    /// 작품 하나의 현재 완결/휴재복귀 알림 설정을 조회한다(#189, 작품 상세 종 아이콘 시트).
    func loadNotificationSetting(novelID: NovelID) async throws(RepositoryError) -> NovelNotificationSetting

    /// PUT은 멱등 — `setting`의 두 값을 항상 함께 보낸다(서버가 부분 갱신을 지원하지 않음).
    func updateNotificationSetting(
        novelID: NovelID,
        setting: NovelNotificationSetting
    ) async throws(RepositoryError)
}
