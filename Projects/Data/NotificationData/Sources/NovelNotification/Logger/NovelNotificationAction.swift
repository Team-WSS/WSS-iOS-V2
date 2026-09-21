//
//  NovelNotificationAction.swift
//  NotificationData
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

enum NovelNotificationAction {
    case loadSubscriptions
    case deleteSubscriptions
    case loadSetting
    case updateSetting

    var name: String {
        switch self {
        case .loadSubscriptions:
            return "loadSubscriptions"
        case .deleteSubscriptions:
            return "deleteSubscriptions"
        case .loadSetting:
            return "loadSetting"
        case .updateSetting:
            return "updateSetting"
        }
    }
}
