//
//  NovelNotificationMapper.swift
//  NotificationData
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import NotificationDomain
import BaseDomain
import BaseData

enum NovelNotificationMapper {
    static func pagedSubscriptions(
        from response: NovelNotificationSubscriptionsResponse
    ) -> PagedNovelNotificationSubscriptions {
        PagedNovelNotificationSubscriptions(
            subscriptions: response.subscriptions.map { subscription(from: $0) },
            isLoadable: response.isLoadable,
            nextSubscriptionID: response.nextSubscriptionId.map { SubscriptionID($0) }
        )
    }

    static func subscription(
        from response: NovelNotificationSubscriptionResponse
    ) -> NovelNotificationSubscription {
        NovelNotificationSubscription(
            id: SubscriptionID(response.subscriptionId),
            novelID: NovelID(response.novelId),
            novelTitle: response.novelTitle,
            novelThumbnailImage: ImageURLResolver.resolve(from: response.novelImage),
            novelAuthor: response.novelAuthor,
            registeredDateText: response.registeredDate
        )
    }

    /// 서버 문자열(`COMPLETION`/`HIATUS_RETURN`) ↔ Domain enum 변환. 조회 쿼리·삭제 요청 양쪽에서 재사용.
    static func serverValue(for type: NovelNotificationType) -> String {
        switch type {
        case .completion:   return "COMPLETION"
        case .hiatusReturn: return "HIATUS_RETURN"
        }
    }
}
