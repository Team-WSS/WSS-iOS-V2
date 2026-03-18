//
//  TrendingFeedsMapper.swift
//  RecommendationData
//
//  Created by Seoyeon Choi on 11/19/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//

import Foundation

import RecommendationDomain
import BaseDomain

extension TrendingFeedsResponse {
    public func toEntity() -> [TrendingFeed] {
        return self.popularNovels.map { $0.toEntity() }
    }
}

extension TrendingFeedResponse {
    public func toEntity() -> TrendingFeed {
        
        return TrendingFeed(
            feedID: FeedID(self.feedId),
            description: self.feedContent,
            isSpoiler: self.isSpoiler,
            likeCount: self.likeCount,
            commentCount: self.commentCount
        )
    }
}
