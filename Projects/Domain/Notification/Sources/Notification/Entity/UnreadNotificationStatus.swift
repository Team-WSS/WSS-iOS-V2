//
//  UnreadNotificationStatus.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Foundation

public struct UnreadNotificationStatus {
    public let hasUnreadNotifications: Bool

    public init(hasUnreadNotifications: Bool) {
        self.hasUnreadNotifications = hasUnreadNotifications
    }
}
