//
//  LoadNovelFeedsUseCase.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadNovelFeedsUseCase {
    func execute(novelID: NovelID,
                 lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed>
}

public final class DefaultLoadNovelFeedsUseCase: LoadNovelFeedsUseCase {
    
    private let feedRepository: FeedRepository
    
    public init(feedRepository: FeedRepository) {
        self.feedRepository = feedRepository
    }
    
    public func execute(novelID: NovelID,
                        lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed> {
        try await feedRepository.fetchNovelFeeds(id: novelID, lastFeedID: lastFeedID)
    }
}
