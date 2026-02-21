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
}
