//
//  ReportFeedUsecase.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public protocol ReportFeedUsecase {
    func reportSpoilerFeed(id: FeedID) async throws
    func reportImproperFeed(id: FeedID) async throws
}

public final class DefaultReportFeedUsecase: ReportFeedUsecase {

    private let feedRepository: FeedRepository

    public init(feedRepository: FeedRepository) {
        self.feedRepository = feedRepository
    }

    public func reportSpoilerFeed(id: FeedID) async throws {
        try await feedRepository.reportSpoilerFeed(id: id)
    }
    
    public func reportImproperFeed(id: FeedID) async throws {
        try await feedRepository.reportImproperFeed(id: id)
    }
}
