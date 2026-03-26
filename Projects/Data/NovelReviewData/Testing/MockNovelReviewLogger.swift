//
//  MockNovelReviewLogger.swift
//  NovelReviewData
//
//  Created by YunhakLee on 3/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


@testable import NovelReviewData

final class MockNovelReviewLogger: NovelReviewLogger {
    struct LoggedError: Equatable {
        let type: NovelReviewErrorType
        let action: NovelReviewAction
    }

    private(set) var loggedErrors: [LoggedError] = []

    func logError(
        type: NovelReviewErrorType,
        action: NovelReviewAction,
        error: Error?
    ) {
        loggedErrors.append(
            LoggedError(type: type, action: action)
        )
    }
}
