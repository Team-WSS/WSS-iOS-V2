//
//  NotificationAction.swift
//  NotificationData
//
//  Created by Codex on 4/29/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

enum NotificationAction {
    case loadNotifications
    case loadDetail
    case markAsRead
    case loadUnreadStatus

    var name: String {
        switch self {
        case .loadNotifications:
            return "loadNotifications"
        case .loadDetail:
            return "loadDetail"
        case .markAsRead:
            return "markAsRead"
        case .loadUnreadStatus:
            return "loadUnreadStatus"
        }
    }
}
