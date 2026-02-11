//
//  ReportSpoilerFeedUsecase.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public protocol ReportSpoilerFeedUsecase {
    func execute(feedID: FeedID) async throws
}

public final class DefaultReportSpoilerFeedUsecase: ReportSpoilerFeedUsecase {

    private let feedRepository: FeedRepository

    public init(feedRepository: FeedRepository) {
        self.feedRepository = feedRepository
    }

    public func execute(feedID: FeedID) async throws {
        try await feedRepository.reportSpoilerFeed(id: feedID)
    }
}
