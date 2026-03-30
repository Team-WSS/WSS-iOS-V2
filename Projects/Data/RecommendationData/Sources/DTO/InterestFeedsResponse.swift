//
//  InterestFeedsResponse.swift
//  RecommendationData
//
//  Created by Seoyeon Choi on 11/19/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//

import Foundation

//MARK: - 홈 - 관심글

public enum InterestFeedsMessage: String {
    case noInterestNovels = "NO_INTEREST_NOVELS"
    case noAssociatedFeeds = "NO_ASSOCIATED_FEEDS"
}

public struct InterestFeedsResponse: Decodable {
    public let recommendFeeds: [InterestFeedResponse]
    public let message: String
}

public struct InterestFeedResponse: Decodable {
    public let novelId: Int
    public let novelTitle: String
    public let novelImage: String
    public let novelRating: Float
    public let novelRatingCount: Int
    
    public let nickname: String
    public let avatarImage: String
    public let feedContent: String
}
