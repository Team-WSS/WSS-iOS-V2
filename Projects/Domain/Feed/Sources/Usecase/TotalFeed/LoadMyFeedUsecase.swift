//
//  LoadMyFeedUsecase.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol LoadMyFeedUsecase {
    func execute(option: MyFeedOption,
                 lastFeedID: FeedID) async throws -> Paginated<TotalFeed>
}

public final class DefaultLoadMyFeedUsecase: LoadMyFeedUsecase {
    
    private let feedRepository: FeedRepositoryProtocol
    
    public init(feedRepository: FeedRepositoryProtocol) {
        self.feedRepository = feedRepository
    }
    
    public func execute(option: MyFeedOption,
                        lastFeedID: FeedID) async throws -> Paginated<TotalFeed> {
        try await feedRepository.fetchMyFeeds(option: option, lastFeedID: lastFeedID)
    }
}
