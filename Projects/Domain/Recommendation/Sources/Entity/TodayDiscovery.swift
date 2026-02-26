//
//  TodayDiscovery.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

/// 홈 - 오늘의 발견

public struct TodayDiscovery {

    public let novelID: NovelID
    
    public let novelTitle: String
    public let novelThumbnailImage: URL?
    public let content: Content
    
    // 타입에 따른 Content 분기 처리
    // novel: 작품 설명
    // userComment: 유저의 작품에 대한 한마디
    public enum Content {
        case novel(description: String)
        case userComment(user: Author, comment: String)
    }
}
