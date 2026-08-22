//
//  NotificationMapper.swift
//  NotificationData
//
//  Created by YunhakLee on 3/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import NotificationDomain
import BaseDomain
import BaseData

enum NotificationMapper {
    static func pagedNotifications(
        from response: PagedNotificationsResponse
    ) -> PagedNotifications {
        PagedNotifications(
            items: response.notifications.map { notificationItem(from: $0) },
            isLoadable: response.isLoadable
        )
    }
    
    static func notificationItem(
        from response: NotificationResponse
    ) -> NotificationItem {
        let notificationID = NotificationID(response.notificationId)
        let iconURL = ImageURLResolver.resolve(from: response.notificationImage)
        let deepLink: NotificationDeeplink
        if response.isNotice {
            deepLink = .notificationDetail(id: notificationID)
        } else if let feedId = response.feedId {
            deepLink = .feedDetail(id: FeedID(feedId))
        } else if let novelId = response.novelId {
            // 완결·휴재 복귀 알림 → 작품 상세. 작품 알림은 `isNotice: false`로 오므로
            // 위 공지 분기에 먼저 걸리지 않는다(#181에서 확인).
            deepLink = .novelDetail(id: NovelID(novelId))
        } else {
            deepLink = .unknown
        }
        
        return NotificationItem(
            id: notificationID,
            iconURL: iconURL,
            title: response.notificationTitle,
            body: response.notificationBody,
            createdAtText: response.createdDate,
            isRead: response.isRead,
            deeplink: deepLink
        )
    }
    
    static func notificationDetail(
        from response: NotificationDetailResponse
    ) -> NotificationDetail {
        return NotificationDetail(
            title: response.notificationTitle,
            createdAtText: response.notificationCreatedDate,
            body: response.notificationDetail
        )
    }
    
    static func unreadNotificationStatus(
        from response: NotificationUnreadStatusResponse
    ) -> UnreadNotificationStatus {
        return UnreadNotificationStatus(hasUnreadNotifications: response.hasUnreadNotifications)
    }
}
