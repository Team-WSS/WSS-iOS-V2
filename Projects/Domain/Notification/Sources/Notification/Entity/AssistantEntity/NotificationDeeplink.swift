//
//  NotificationDeeplink.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain

public enum NotificationDeeplink: Equatable {
    case feedDetail(id: FeedID)
    case notificationDetail(id: NotificationID)
    case unknown
}
