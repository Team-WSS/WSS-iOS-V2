//
//  TrendingFeedsResponse.swift
//  RecommendationData
//
//  Created by Seoyeon Choi on 11/19/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//

import Foundation

//MARK: - 홈 - 지금 뜨는 글

public struct TrendingFeedsResponse: Decodable {
    public let popularFeeds: [TrendingFeedResponse]
}

public struct TrendingFeedResponse: Decodable {
    public let feedId: Int
    public let feedContent: String
    public let likeCount: Int
    public let commentCount: Int
    public let isSpoiler: Bool
    public let isPublic: Bool
}
