//
//  NovelNotificationSettingResponse.swift
//  NotificationData
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

struct NovelNotificationSettingResponse: Decodable {
    let isCompletionNotificationEnabled: Bool
    let isHiatusReturnNotificationEnabled: Bool
}
