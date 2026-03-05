//
//  LoadMyFeedUseCase.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public protocol LoadMyFeedsUseCase {
    func execute(option: MyFeedOption,
                 lastFeedID: FeedID) async throws -> Paginated<TotalFeed>
}

public final class DefaultLoadMyFeedsUseCase: LoadMyFeedsUseCase {
    
    private let feedRepository: FeedRepository
    
    public init(feedRepository: FeedRepository) {
        self.feedRepository = feedRepository
    }
    
    public func execute(option: MyFeedOption,
                        lastFeedID: FeedID) async throws -> Paginated<TotalFeed> {
        try await feedRepository.fetchMyFeeds(option: option, lastFeedID: lastFeedID)
    }
}
