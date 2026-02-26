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
    public let likeCount: Int
    public let commentCount: Int
}
