//
//  MockPushSettingLogger.swift
//  NotificationData
//
//  Created by YunhakLee on 3/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


@testable import NotificationData

final class MockPushSettingLogger: PushSettingLogger {
    struct LoggedError: Equatable {
        let type: PushSettingErrorType
        let action: PushSettingAction
    }

    private(set) var loggedErrors: [LoggedError] = []

    func logError(
        type: PushSettingErrorType,
        action: PushSettingAction,
        error: Error?
    ) {
        loggedErrors.append(
            LoggedError(type: type, action: action)
        )
    }
}
