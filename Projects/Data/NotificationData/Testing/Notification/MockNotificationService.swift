//
//  MockNotificationService.swift
//  NotificationData
//
//  Created by YunhakLee on 3/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


@testable import NotificationData

final class MockNotificationService: NotificationService {

    var getNotificationsResult: Result<PagedNotificationsResponse, Error>!
    var getNotificationDetailResult: Result<NotificationDetailResponse, Error>!
    var postNotificationReadResult: Result<Void, Error> = .success(())
    var getUnreadStatusResult: Result<NotificationUnreadStatusResponse, Error>!

    private(set) var requestedQuery: NotificationQuery?
    private(set) var requestedDetailID: Int?
    private(set) var markedAsReadID: Int?

    func getNotifications(_ query: NotificationQuery) async throws -> PagedNotificationsResponse {
        requestedQuery = query
        return try getNotificationsResult.get()
    }

    func getNotificationDetail(notificationId: Int) async throws -> NotificationDetailResponse {
        requestedDetailID = notificationId
        return try getNotificationDetailResult.get()
    }

    func postNotificationRead(notificationId: Int) async throws {
        markedAsReadID = notificationId
        _ = try postNotificationReadResult.get()
    }

    func getNotificationUnreadStatus() async throws -> NotificationUnreadStatusResponse {
        return try getUnreadStatusResult.get()
    }
}
