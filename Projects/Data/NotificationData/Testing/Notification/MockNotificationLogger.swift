//
//  MockNotificationLogger.swift
//  NotificationData
//
//  Created by YunhakLee on 3/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


@testable import NotificationData

final class MockNotificationLogger: NotificationLogger {

    struct LoggedError: Equatable {
        let type: NotificationErrorType
        let action: NotificationAction
    }

    private(set) var loggedErrors: [LoggedError] = []

    func logError(
        type: NotificationErrorType,
        action: NotificationAction,
        error: Error?
    ) {
        loggedErrors.append(.init(type: type, action: action))
    }
}
