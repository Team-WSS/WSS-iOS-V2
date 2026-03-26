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

enum NotificationMapper {
    static func pagedNotifications(
        from response: NotificationListResponse
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
        let iconURL = URL(string: response.notificationImage)
        let deepLink: NotificationDeeplink
        if response.isNotice {
            deepLink = .notificationDetail(id: notificationID)
        } else if let feedId = response.feedId {
            deepLink = .feedDetail(id: FeedID(feedId))
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
}
