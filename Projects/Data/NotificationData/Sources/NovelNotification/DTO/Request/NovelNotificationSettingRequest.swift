//
//  NovelNotificationSettingRequest.swift
//  NotificationData
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// PUT은 멱등 — 두 값을 항상 함께 보낸다(서버가 부분 갱신을 지원하지 않음).
struct NovelNotificationSettingRequest: Encodable {
    let isCompletionNotificationEnabled: Bool
    let isHiatusReturnNotificationEnabled: Bool
}
