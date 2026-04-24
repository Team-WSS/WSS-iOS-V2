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
    public let contentDescription: String
    
    public enum Content {
        case novel
        case userComment(user: Author)
    }
    
    public var title: String {
        switch content {
        case .novel:
            return "작품 소개"
        case .userComment(let user):
            return "\(user.nickname)의 한마디"
        }
    }
    
    public var description: String {
        contentDescription
    }
    
    public init(
        novelID: NovelID,
        novelTitle: String,
        novelThumbnailImage: URL?,
        content: Content,
        contentDescription: String
    ) {
        self.novelID = novelID
        self.novelTitle = novelTitle
        self.novelThumbnailImage = novelThumbnailImage
        self.content = content
        self.contentDescription = contentDescription
    }
}
