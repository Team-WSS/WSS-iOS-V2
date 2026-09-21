//
//  LoadUserFeedsUseCase.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadUserFeedsUseCase: Sendable {
    func execute(userID: UserID,
                 nickname: String,
                 profileImage: URL?,
                 lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed>
}

public final class DefaultLoadUserFeedsUseCase: LoadUserFeedsUseCase {

    private let feedRepository: FeedRepository

    public init(feedRepository: FeedRepository) {
        self.feedRepository = feedRepository
    }

    public func execute(userID: UserID,
                        nickname: String,
                        profileImage: URL?,
                        lastFeedID: FeedID) async throws(RepositoryError) -> Paginated<TotalFeed> {
        try await feedRepository.fetchUserFeeds(id: userID, nickname: nickname, profileImage: profileImage, lastFeedID: lastFeedID)
    }
}
