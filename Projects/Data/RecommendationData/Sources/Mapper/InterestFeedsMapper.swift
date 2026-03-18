//
//  InterestFeedsMapper.swift
//  RecommendationData
//
//  Created by Seoyeon Choi on 11/19/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//

import Foundation

import RecommendationDomain
import BaseDomain

extension InterestFeedsResponse {
    public func toEntity() -> [InterestFeed] {
        return self.recommendFeeds.map { $0.toEntity() }
    }
}

extension InterestFeedResponse {
    public func toEntity() -> InterestFeed {
        let novelImageURL = URL(string: self.novelImage)
        let authorProfileImageURL = URL(string: self.avatarImage)
    
        return InterestFeed(
            novelID: NovelID(self.novelId),
            novelTitle: self.novelTitle,
            novelThumbnailImage: novelImageURL,
            novelRating: self.novelRating,
            novelRatingCount: self.novelRatingCount,
            user: Author(nickname: self.nickname,
                         profileImage: authorProfileImageURL),
            userComment: self.feedContent)
    }
}
