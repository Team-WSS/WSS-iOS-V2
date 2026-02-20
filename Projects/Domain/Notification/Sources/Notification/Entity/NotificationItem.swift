//
//  NotificationItem.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public struct NotificationItem: Equatable {
    public let id: NotificationID
    public let type: NotificationType
    public let iconURL: URL?
    public let title: String
    public let body: String
    public let createdAtText: String
    public let isRead: Bool
    public let deeplink: NotificationDeeplink?
    
    public init(
        id: NotificationID,
        type: NotificationType,
        iconURL: URL?,
        title: String,
        body: String,
        createdAtText: String,
        isRead: Bool,
        deeplink: NotificationDeeplink?
    ) {
        self.id = id
        self.type = type
        self.iconURL = iconURL
        self.title = title
        self.body = body
        self.createdAtText = createdAtText
        self.isRead = isRead
        self.deeplink = deeplink
    }
}
