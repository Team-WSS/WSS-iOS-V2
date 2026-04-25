//
//  MockSocialLogger.swift
//  SocialDataTesting
//
//  Created by YunhakLee on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

@testable import SocialData

public final class MockSocialLogger: SocialLogger {

    public private(set) var logErrorCallCount = 0
    public private(set) var loggedTypes: [SocialErrorType] = []
    public private(set) var loggedActions: [SocialAction] = []
    public private(set) var loggedErrors: [Error?] = []

    public init() {}

    public func logError(
        type: SocialErrorType,
        action: SocialAction,
        error: Error?
    ) {
        logErrorCallCount += 1
        loggedTypes.append(type)
        loggedActions.append(action)
        loggedErrors.append(error)
    }
}
