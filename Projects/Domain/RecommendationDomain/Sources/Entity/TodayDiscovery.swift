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

public struct TodayDiscovery: Sendable {

    public let novelID: NovelID

    public let novelTitle: String
    public let novelThumbnailImage: URL?
    public let novelAuthor: String
    public let novelGenre: NovelGenre
    public let publicationStatus: NovelPublicationStatus
    public let keywords: [String]

    public let content: Content
    public let contentDescription: String

    /// 카드 본문의 출처. `.novel`이면 작품 소개글, `.userComment`면 그 유저가 남긴 한마디다.
    /// 서버가 nickname·avatarImage를 주는지로 갈린다.
    public enum Content: Sendable {
        case novel
        case userComment(user: Author)
    }

    public init(
        novelID: NovelID,
        novelTitle: String,
        novelThumbnailImage: URL?,
        novelAuthor: String,
        novelGenre: NovelGenre,
        publicationStatus: NovelPublicationStatus,
        keywords: [String],
        content: Content,
        contentDescription: String
    ) {
        self.novelID = novelID
        self.novelTitle = novelTitle
        self.novelThumbnailImage = novelThumbnailImage
        self.novelAuthor = novelAuthor
        self.novelGenre = novelGenre
        self.publicationStatus = publicationStatus
        self.keywords = keywords
        self.content = content
        self.contentDescription = contentDescription
    }
}
