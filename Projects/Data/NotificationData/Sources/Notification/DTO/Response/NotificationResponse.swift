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
    /// 작품 알림(완결·휴재 복귀)이 가리키는 작품. 공지·피드 알림에선 null로 온다.
    var novelId: Int?
}
