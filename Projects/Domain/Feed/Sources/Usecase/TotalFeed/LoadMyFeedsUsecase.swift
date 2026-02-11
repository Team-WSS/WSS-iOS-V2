//
//  LoadMyFeedUsecase.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public protocol LoadMyFeedsUsecase {
    func execute(option: MyFeedOption,
                 lastFeedID: FeedID) async throws -> Paginated<TotalFeed>
}

public final class DefaultLoadMyFeedsUsecase: LoadMyFeedsUsecase {
    
    private let feedRepository: FeedRepository
    
    public init(feedRepository: FeedRepository) {
        self.feedRepository = feedRepository
    }
    
    public func execute(option: MyFeedOption,
                        lastFeedID: FeedID) async throws -> Paginated<TotalFeed> {
        try await feedRepository.fetchMyFeeds(option: option, lastFeedID: lastFeedID)
    }
}
