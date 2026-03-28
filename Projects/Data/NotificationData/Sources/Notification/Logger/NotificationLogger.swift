//
//  NotificationLogger.swift
//  NotificationData
//
//  Created by YunhakLee on 3/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Logger

public protocol NotificationLogger {
    func logError(
        type: NotificationErrorType,
        action: NotificationAction,
        error: Error?
    )
}

public struct DefaultNotificationLogger: NotificationLogger {
    private let base: Logger
    
    public init(base: Logger) {
        self.base = base
    }
    
    public func logError(
        type: NotificationErrorType,
        action: NotificationAction,
        error: Error?
    ) {
        var message = "📦 [NotificationData] \(action.text) \(type.text) error"
        if let error {
            message += ": \(error)"
        }
        
        base.error(message)
    }
}

public enum NotificationAction {
    case loadNotifications
    case loadDetail
    case markAsRead
    case loadUnreadStatus
    
    var text: String {
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

public enum NotificationErrorType {
    case network
    case unknown
    
    var text: String {
        switch self {
        case .network:
            return "network"
        case .unknown:
            return "unknown"
        }
    }
}
