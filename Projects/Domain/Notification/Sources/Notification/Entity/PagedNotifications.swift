//
//  PagedNotifications.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


public struct PagedNotifications: Equatable {
    public let items: [NotificationItem]
    public let isLoadable: Bool

    public init(items: [NotificationItem], isLoadable: Bool) {
        self.items = items
        self.isLoadable = isLoadable
    }
}
