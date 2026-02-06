//
//  LoadSosoFeedUsecase.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol LoadSosoFeedUsecase {
    func execute(option: SosoFeedOption,
                 lastFeedID: FeedID) async throws -> Paginated<TotalFeed>
}

public final class DefaultLoadSosoFeedUsecase: LoadSosoFeedUsecase {
    
    private let feedRepository: FeedRepositoryProtocol
    
    public init(feedRepository: FeedRepositoryProtocol) {
        self.feedRepository = feedRepository
    }
    
    public func execute(option: SosoFeedOption,
                        lastFeedID: FeedID) async throws -> Paginated<TotalFeed> {
        try await feedRepository.fetchSosoFeeds(option: option, lastFeedID: lastFeedID)
    }
}
