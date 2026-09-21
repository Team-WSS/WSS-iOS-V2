//
//  NotificationQuery.swift
//  NotificationData
//
//  Created by YunhakLee on 11/25/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//


import Foundation
import Networking

struct NotificationQuery: QueryItemConvertible {
    let lastNotificationId: Int
    let size: Int
}
