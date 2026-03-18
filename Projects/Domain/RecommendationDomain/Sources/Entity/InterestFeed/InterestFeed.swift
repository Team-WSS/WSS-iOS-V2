//
//  InterestFeed.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

/// 홈 - 관심글

public struct InterestFeed {
    
    public let novelID: NovelID
    
    public let novelTitle: String
    public let novelThumbnailImage: URL?
    public let novelRating: Float
    public let novelRatingCount: Int
    
    public let user: Author
    public let userComment: String
    
    public init(novelID: NovelID,
                novelTitle: String,
                novelThumbnailImage: URL?,
                novelRating: Float,
                novelRatingCount: Int,
                user: Author,
                userComment: String) {
        self.novelID = novelID
        self.novelTitle = novelTitle
        self.novelThumbnailImage = novelThumbnailImage
        self.novelRating = novelRating
        self.novelRatingCount = novelRatingCount
        self.user = user
        self.userComment = userComment
    }
}
