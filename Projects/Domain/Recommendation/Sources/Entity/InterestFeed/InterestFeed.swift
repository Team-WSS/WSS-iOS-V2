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
}
