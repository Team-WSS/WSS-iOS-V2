//
//  MockFeedLogger.swift
//  FeedDataTesting
//
//  Created by Lee Wonsun on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

@testable import FeedData

public final class MockFeedLogger: FeedLogger {

    public private(set) var logErrorCallCount = 0
    public private(set) var loggedTypes: [FeedErrorType] = []
    public private(set) var loggedActions: [FeedAction] = []
    public private(set) var loggedErrors: [Error?] = []

    public init() {}

    public func logError(
        type: FeedErrorType,
        action: FeedAction,
        error: Error?
    ) {
        logErrorCallCount += 1
        loggedTypes.append(type)
        loggedActions.append(action)
        loggedErrors.append(error)
    }
}
