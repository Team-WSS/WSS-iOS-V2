//
//  NotificationResponse.swift
//  NotificationData
//
//  Created by YunhakLee on 11/25/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//


import Foundation

struct NotificationResponse: Decodable {
    var notificationId: Int
    var notificationImage: String
    var notificationTitle: String
    var notificationBody: String
    var createdDate: String
    var isRead: Bool
    var isNotice: Bool
    var feedId: Int?
}
