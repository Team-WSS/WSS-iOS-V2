//
//  NotificationDetailResponse.swift
//  NotificationData
//
//  Created by YunhakLee on 11/25/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//


import Foundation

struct NotificationDetailResponse: Decodable {
    var notificationTitle: String
    var notificationCreatedDate: String
    var notificationDetail: String
}
