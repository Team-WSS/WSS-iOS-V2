//
//  LoadFeedDetailUseCase.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public protocol LoadFeedDetailUseCase {
    func execute(feedID: FeedID) async throws -> FeedDetail
}

public final class DefaultLoadFeedUseCase: LoadFeedDetailUseCase {
    
    private let feedRepository: FeedRepository
    
    public init(feedRepository: FeedRepository) {
        self.feedRepository = feedRepository
    }
    
    public func execute(feedID: FeedID) async throws -> FeedDetail {
        try await feedRepository.fetchFeedDetail(id: feedID)
    }
}
