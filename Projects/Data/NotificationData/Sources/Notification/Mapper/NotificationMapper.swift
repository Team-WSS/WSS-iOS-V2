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
        // **id 존재를 isNotice보다 우선**한다 — 피드·작품 상세로 가는 알림은 각각 feedId·novelId를 달고 온다.
        // 완결·휴재 복귀 알림은 novelId가 있으면 서버가 isNotice를 뭘로 주든(true/false) 작품 상세로 간다
        // ("novelId 있으면 다 작품 상세" 규칙). 순수 공지는 id 없이 isNotice만으로 알림 상세로 간다.
        // (이전엔 isNotice를 먼저 봐서, 완결 알림이 isNotice:true로 오면 알림 상세로 새는 위험이 있었다.)
        if let feedId = response.feedId {
            deepLink = .feedDetail(id: FeedID(feedId))
        } else if let novelId = response.novelId {
            deepLink = .novelDetail(id: NovelID(novelId))
        } else if response.isNotice {
            deepLink = .notificationDetail(id: notificationID)
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
