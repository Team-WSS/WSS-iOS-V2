//
//  TotalFeedEntity.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/29/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct TotalFeedEntity {

    public let feedId: FeedID
    public let createdDate: String
    public let content: String
    public let author: FeedAuthor

    public let likeCount: Int
    public let isLiked: Bool
    public let commentCount: Int

    public let connectedNovel: ConnectedNovel?

    public let isSpoiler: Bool
    public let isModified: Bool
    public let isPublic: Bool
    
    public let thumbnailImageURL: URL?
    public let imageCount: Int
    
    public init(feedId: FeedID,
                createdDate: String,
                content: String,
                author: FeedAuthor,
                likeCount: Int,
                isLiked: Bool,
                commentCount: Int,
                connectedNovel: ConnectedNovel?,
                isSpoiler: Bool,
                isModified: Bool,
                isPublic: Bool,
                thumbnailImageURL: URL?,
                imageCount: Int) {
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
        self.thumbnailImageURL = thumbnailImageURL
        self.imageCount = imageCount
    }
}
