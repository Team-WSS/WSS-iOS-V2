//
//  MockPushSettingLogger.swift
//  NotificationDataTests
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