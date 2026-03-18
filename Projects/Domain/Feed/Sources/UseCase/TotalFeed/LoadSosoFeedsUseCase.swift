//
//  LoadSosoFeedsUseCase.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadSosoFeedsUseCase {
    func execute(option: SosoFeedOption,
                 lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed>
}

public final class DefaultLoadSosoFeedsUseCase: LoadSosoFeedsUseCase {
    
    private let feedRepository: FeedRepository
    
    public init(feedRepository: FeedRepository) {
        self.feedRepository = feedRepository
    }
    
    public func execute(option: SosoFeedOption,
                        lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed> {
        try await feedRepository.fetchSosoFeeds(option: option, lastFeedID: lastFeedID)
    }
}
