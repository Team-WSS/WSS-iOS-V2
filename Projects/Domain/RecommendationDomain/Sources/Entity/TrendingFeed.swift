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

    /// 글이 달린 작품. 목록이 작품 제목·표지와 함께 보이므로 피드와 한 몸으로 온다.
    public let novelTitle: String
    public let novelThumbnailImage: URL?
    public let novelGenre: NovelGenre

    public let description: String
    public let isSpoiler: Bool
    public let likeCount: Int
    public let commentCount: Int

    public init(
        feedID: FeedID,
        novelTitle: String,
        novelThumbnailImage: URL?,
        novelGenre: NovelGenre,
        description: String,
        isSpoiler: Bool,
        likeCount: Int,
        commentCount: Int
    ) {
        self.feedID = feedID
        self.novelTitle = novelTitle
        self.novelThumbnailImage = novelThumbnailImage
        self.novelGenre = novelGenre
        self.description = description
        self.isSpoiler = isSpoiler
        self.likeCount = likeCount
        self.commentCount = commentCount
    }
}
