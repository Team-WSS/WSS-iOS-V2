//
//  FeedLikeUsecase.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol FeedLikeUsecase {
    func like(feedID: FeedID) async throws
    func unlike(feedID: FeedID) async throws
}

public final class DefaultLikeUsecase: FeedLikeUsecase {
    
    private let feedRepository: FeedRepository
    
    public init(feedRepository: FeedRepository) {
        self.feedRepository = feedRepository
    }
    
    public func like(feedID: FeedID) async throws {
        try await feedRepository.addLike(id: feedID)
    }
    
    public func unlike(feedID: FeedID) async throws {
        try await feedRepository.deleteLike(id: feedID)
    }
}
