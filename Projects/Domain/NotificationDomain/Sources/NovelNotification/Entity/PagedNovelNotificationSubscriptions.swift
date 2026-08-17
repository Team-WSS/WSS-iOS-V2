//
//  PagedNovelNotificationSubscriptions.swift
//  NotificationDomain
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain

/// 작품 알림 구독 목록 페이지 — `PagedNotifications`와 달리 서버가 다음 페이지 커서(`nextSubscriptionID`)를
/// 명시적으로 내려준다(항목의 마지막 `id`로 유추하지 않는다).
public struct PagedNovelNotificationSubscriptions: Equatable {
    public let subscriptions: [NovelNotificationSubscription]
    public let isLoadable: Bool
    public let nextSubscriptionID: SubscriptionID?

    public init(
        subscriptions: [NovelNotificationSubscription],
        isLoadable: Bool,
        nextSubscriptionID: SubscriptionID?
    ) {
        self.subscriptions = subscriptions
        self.isLoadable = isLoadable
        self.nextSubscriptionID = nextSubscriptionID
    }
}
