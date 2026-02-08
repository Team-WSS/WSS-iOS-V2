//
//  ReportImproperFeedUsecase.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol ReportImproperFeedUsecase {
    func execute(feedID: FeedID) async throws
}

public final class DefaultReportImproperFeedUsecase: ReportImproperFeedUsecase {
    
    private let feedRepository: FeedRepository
    
    public init(feedRepository: FeedRepository) {
        self.feedRepository = feedRepository
    }
    
    public func execute(feedID: FeedID) async throws {
        try await feedRepository.reportImproperFeed(id: feedID)
    }
}
