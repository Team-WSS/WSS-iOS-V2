//
//  RecommendedNovel.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

/// 홈 - 선호 장르 기반 작품

public struct RecommendedNovel {
    
    public let novelID: NovelID
    
    public let novelTitle: String
    public let novelThumbnailImage: URL?
    public let novelAuthors: [String]
    
    public let interestCount: Int
    public let ratingCount: Int
    public let rating: Float
    
    public init(novelID: NovelID, novelTitle: String, novelThumbnailImage: URL?, novelAuthors: [String], interestCount: Int, ratingCount: Int, rating: Float) {
        self.novelID = novelID
        self.novelTitle = novelTitle
        self.novelThumbnailImage = novelThumbnailImage
        self.novelAuthors = novelAuthors
        self.interestCount = interestCount
        self.ratingCount = ratingCount
        self.rating = rating
    }
}
