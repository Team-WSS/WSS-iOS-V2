//
//  NovelNotificationSubscriptionsQuery.swift
//  NotificationData
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking

struct NovelNotificationSubscriptionsQuery: QueryItemConvertible {
    let notificationType: String
    let lastSubscriptionId: Int
    let size: Int
}
