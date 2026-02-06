//
//  LoadUserFeedUsecase.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol LoadUserUsecase {
    func execute(userID: UserID,
                 lastFeedID: FeedID) async throws -> Paginated<TotalFeed>
}

public final class DefaultLoadUserFeedUsecase: LoadUserUsecase {
    
    private let feedRepository: FeedRepositoryProtocol
    
    public init(feedRepository: FeedRepositoryProtocol) {
        self.feedRepository = feedRepository
    }
    
    public func execute(userID: UserID,
                        lastFeedID: FeedID) async throws -> Paginated<TotalFeed> {
        try await feedRepository.fetchUserFeeds(id: userID, lastFeedID: lastFeedID)
    }
}
