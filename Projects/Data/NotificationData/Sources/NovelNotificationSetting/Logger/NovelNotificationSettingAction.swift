//
//  NovelNotificationSettingAction.swift
//  NotificationData
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

enum NovelNotificationSettingAction {
    case loadSetting
    case updateSetting

    var name: String {
        switch self {
        case .loadSetting:
            return "loadSetting"
        case .updateSetting:
            return "updateSetting"
        }
    }
}
