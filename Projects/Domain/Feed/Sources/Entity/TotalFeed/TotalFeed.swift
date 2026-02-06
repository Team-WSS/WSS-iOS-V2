//
//  TotalFeed.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/29/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct TotalFeed {

    public let feedId: FeedID
    public private(set) var createdDate: String
    public private(set) var content: String
    
    public private(set) var author: FeedAuthor

    public private(set) var likeCount: Int
    public private(set) var isLiked: Bool
    public private(set) var commentCount: Int

    public private(set) var connectedNovel: ConnectedNovel?

    public private(set) var isSpoiler: Bool
    public private(set) var isModified: Bool
    public private(set) var isPublic: Bool
    
    public private(set) var thumbnailImageURL: ImageWrapper?
    public private(set) var imageCount: Int
    
    //MARK: - Policy
    
    public mutating func isMyFeed(myID: UserID) -> Bool {
        author.userId == myID
    }
    
    public mutating func addLike() {
        likeCount += 1
        isLiked = true
    }
    
    public mutating func removeLike() {
        likeCount -= 1
        isLiked = false
    }
    
    public mutating func hasImage() -> Bool {
        imageCount > 0 && thumbnailImageURL != nil
    }
    
    public mutating func roundedRating() {
        if let rating = connectedNovel?.rating {
            let rounded = round(rating * 10) / 10
        }
    }
}
