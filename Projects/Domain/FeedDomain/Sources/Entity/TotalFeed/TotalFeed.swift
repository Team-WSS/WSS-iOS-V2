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

    /// 재조회로 받은 서버 항목(self)에 **로컬 항목의 좋아요 상태(isLiked·likeCount)만** 얹은 사본.
    ///
    /// 재진입 조용한 재조회의 통째 교체가 낙관 좋아요 토글과 겹칠 때 쓴다 — 서버 응답이 토글 이전
    /// 스냅샷일 수 있어 그대로 교체하면 방금 누른 좋아요가 시각적으로 풀린다. 좋아요 두 필드만
    /// 로컬 우선으로 보존하고 **본문·댓글수·수정 여부 등 나머지는 서버 값을 따른다**(셀 전체를
    /// 로컬로 되돌리면 그 사이 서버에서 바뀐 다른 값까지 버리게 된다 — #236 리뷰).
    public func preservingLikeState(of local: TotalFeed) -> TotalFeed {
        TotalFeed(
            feedId: feedId,
            createdDate: createdDate,
            content: content,
            author: author,
            likeCount: local.likeCount,
            isLiked: local.isLiked,
            commentCount: commentCount,
            connectedNovel: connectedNovel,
            isSpoiler: isSpoiler,
            isModified: isModified,
            isPublic: isPublic,
            isMyFeed: isMyFeed,
            thumbnailImageURL: thumbnailImageURL,
            imageCount: imageCount
        )
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
