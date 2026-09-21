//
//  TrendingFeedsResponse.swift
//  RecommendationData
//
//  Created by Seoyeon Choi on 11/19/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//

import Foundation

//MARK: - 홈 - 지금 뜨는 글

struct TrendingFeedsResponse: Decodable {
    public let popularFeeds: [TrendingFeedResponse]
}

struct TrendingFeedResponse: Decodable {
    public let feedId: Int
    public let feedContent: String
    public let likeCount: Int
    public let commentCount: Int
    public let isSpoiler: Bool
    public let isPublic: Bool

    /// 글이 달린 작품. 홈 목록이 작품 제목·표지·장르 마크를 함께 그린다.
    public let novelTitle: String
    public let novelImage: String
    public let novelGenre: String
}
