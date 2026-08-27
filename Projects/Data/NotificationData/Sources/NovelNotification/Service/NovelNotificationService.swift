//
//  NovelNotificationService.swift
//  NotificationData
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

protocol NovelNotificationService: Sendable {
    func getSubscriptions(_ query: NovelNotificationSubscriptionsQuery) async throws -> NovelNotificationSubscriptionsResponse
    func deleteSubscriptions(_ request: NovelNotificationUnsubscribeRequest) async throws
}
