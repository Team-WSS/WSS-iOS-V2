//
//  FCMTokenRequest.swift
//  NotificationData
//
//  Created by YunhakLee on 11/25/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//


import Foundation

struct FCMTokenRequest: Encodable, Equatable {
    let fcmToken: String
    let deviceIdentifier: String
}
