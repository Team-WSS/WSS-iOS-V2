//
//  NovelNotificationSettingMapper.swift
//  NotificationData
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import NotificationDomain

enum NovelNotificationSettingMapper {
    static func setting(from response: NovelNotificationSettingResponse) -> NovelNotificationSetting {
        NovelNotificationSetting(
            isCompletionNotificationEnabled: response.isCompletionNotificationEnabled,
            isHiatusReturnNotificationEnabled: response.isHiatusReturnNotificationEnabled
        )
    }

    static func request(from setting: NovelNotificationSetting) -> NovelNotificationSettingRequest {
        NovelNotificationSettingRequest(
            isCompletionNotificationEnabled: setting.isCompletionNotificationEnabled,
            isHiatusReturnNotificationEnabled: setting.isHiatusReturnNotificationEnabled
        )
    }
}
