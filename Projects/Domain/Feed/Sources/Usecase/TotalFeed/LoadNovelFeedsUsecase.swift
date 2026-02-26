//
//  LoadNovelFeedsUsecase.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public protocol LoadNovelFeedsUsecase {
    func execute(novelID: NovelID,
                 lastFeedID: FeedID) async throws -> Paginated<TotalFeed>
}

public final class DefaultLoadNovelFeedsUsecase: LoadNovelFeedsUsecase {
    
    private let feedRepository: FeedRepository
    
    public init(feedRepository: FeedRepository) {
        self.feedRepository = feedRepository
    }
    
    public func execute(novelID: NovelID,
                        lastFeedID: FeedID) async throws -> Paginated<TotalFeed> {
        try await feedRepository.fetchNovelFeeds(id: novelID, lastFeedID: lastFeedID)
    }
}
