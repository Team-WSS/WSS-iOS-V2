//
//  LoadUserFeedsUsecase.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol LoadUserFeedsUsecase {
    func execute(userID: UserID,
                 lastFeedID: FeedID) async throws -> Paginated<TotalFeed>
}

public final class DefaultLoadUserFeedsUsecase: LoadUserFeedsUsecase {
    
    private let feedRepository: FeedRepository
    
    public init(feedRepository: FeedRepository) {
        self.feedRepository = feedRepository
    }
    
    public func execute(userID: UserID,
                        lastFeedID: FeedID) async throws -> Paginated<TotalFeed> {
        try await feedRepository.fetchUserFeeds(id: userID, lastFeedID: lastFeedID)
    }
}
