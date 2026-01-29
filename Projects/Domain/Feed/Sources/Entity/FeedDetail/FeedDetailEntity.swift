//
//  FeedDetailEntity.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/29/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct FeedDetailEntity {
    
    public let userId: UserID
    public let userProfileImageURL: URL?
    public let userName: String
    public let createdDate: String
    public let isModified: Bool
    
    public let feedContent: String
    public let feedImageURLs: [URL?]
    
    public let connectedNovel: ConnectedNovelDetail?
    
    public let likeCount: Int
    public let isLiked: Bool
    public let commentCount: Int
    
    public init(userId: UserID,
                userProfileImageURL: URL?,
                userName: String,
                createdDate: String,
                isModified: Bool,
                feedContent: String,
                feedImageURLs: [URL?],
                connectedNovel: ConnectedNovelDetail?,
                likeCount: Int,
                isLiked: Bool,
                commentCount: Int)
    {
        self.userId = userId
        self.userProfileImageURL = userProfileImageURL
        self.userName = userName
        self.createdDate = createdDate
        self.isModified = isModified
        self.feedContent = feedContent
        self.feedImageURLs = feedImageURLs
        self.connectedNovel = connectedNovel
        self.likeCount = likeCount
        self.isLiked = isLiked
        self.commentCount = commentCount
    }
}
