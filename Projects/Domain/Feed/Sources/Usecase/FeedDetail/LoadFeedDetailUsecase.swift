//
//  LoadFeedDetailUsecase.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol LoadFeedDetailUsecase {
    func execute(feedID: FeedID) async throws -> FeedDetail
}

public final class DefaultLoadFeedUsecase: LoadFeedDetailUsecase {
    private let feedRepository: FeedRepositoryProtocol
    
    public init(feedRepository: FeedRepositoryProtocol) {
        self.feedRepository = feedRepository
    }
    
    public func execute(feedID: FeedID) async throws -> FeedDetail {
        try await feedRepository.fetchFeedDetail(id: feedID)
    }
}
