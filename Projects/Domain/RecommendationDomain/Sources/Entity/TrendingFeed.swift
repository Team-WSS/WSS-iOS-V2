//
//  TrendingFeed.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

/// 홈 - 지금 뜨는 글 

public struct TrendingFeed {
    public let feedID: FeedID
    
    public let description: String
    public let isSpoiler: Bool
    public let likeCount: Int
    public let commentCount: Int
    
    public var displayDescription: String {
        isSpoiler ? "스포일러가 포함된 글 보기" : description
    }
    
    public init(
        feedID: FeedID,
        description: String,
        isSpoiler: Bool,
        likeCount: Int,
        commentCount: Int
    ) {
        self.feedID = feedID
        self.description = description
        self.isSpoiler = isSpoiler
        self.likeCount = likeCount
        self.commentCount = commentCount
    }
}
