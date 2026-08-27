//
//  NovelNotificationSubscriptionsResponse.swift
//  NotificationData
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

struct NovelNotificationSubscriptionsResponse: Decodable {
    let isLoadable: Bool
    let nextSubscriptionId: Int?
    let subscriptions: [NovelNotificationSubscriptionResponse]
}

struct NovelNotificationSubscriptionResponse: Decodable {
    let subscriptionId: Int
    let novelId: Int
    let novelImage: String
    let novelTitle: String
    let novelAuthor: String
    let registeredDate: String
}
