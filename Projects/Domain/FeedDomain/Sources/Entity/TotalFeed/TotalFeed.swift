//
//  TotalFeed.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/29/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public struct TotalFeed: Equatable, Sendable {
    
    public let feedId: FeedID
    public static func == (lhs: TotalFeed, rhs: TotalFeed) -> Bool {
        lhs.feedId == rhs.feedId
    }
    
    public let createdDate: String
    public let content: String
    
    public private(set) var author: Author
    
    public private(set) var likeCount: Int
    public private(set) var isLiked: Bool
    public private(set) var commentCount: Int
    
    public private(set) var connectedNovel: ConnectedNovel?
    
    public private(set) var isSpoiler: Bool
    public private(set) var isModified: Bool
    public private(set) var isPublic: Bool
    /// 로그인 사용자의 글인지 — 셀 액션 분기(수정/삭제 vs 신고, 프로필 이동 차단)에 쓴다.
    public let isMyFeed: Bool

    public private(set) var thumbnailImageURL: URL?
    public private(set) var imageCount: Int
    
    // MARK: - Policy
    
    public enum PolicyError: Error, Equatable {
        case negativeLikeCount
    }
    
    public mutating func toggleLike() throws {
        if isLiked {
            guard likeCount > 0 else {
                throw PolicyError.negativeLikeCount
            }
            likeCount -= 1
        } else {
            likeCount += 1
        }
        isLiked.toggle()
    }
    
    public init(
        feedId: FeedID,
        createdDate: String,
        content: String,
        author: Author,
        likeCount: Int,
        isLiked: Bool,
        commentCount: Int,
        connectedNovel: ConnectedNovel? = nil,
        isSpoiler: Bool,
        isModified: Bool,
        isPublic: Bool,
        isMyFeed: Bool,
        thumbnailImageURL: URL? = nil,
        imageCount: Int
    ) {
        self.feedId = feedId
        self.createdDate = createdDate
        self.content = content
        self.author = author
        self.likeCount = likeCount
        self.isLiked = isLiked
        self.commentCount = commentCount
        self.connectedNovel = connectedNovel
        self.isSpoiler = isSpoiler
        self.isModified = isModified
        self.isPublic = isPublic
        self.isMyFeed = isMyFeed
        self.thumbnailImageURL = thumbnailImageURL
        self.imageCount = imageCount
    }
}
