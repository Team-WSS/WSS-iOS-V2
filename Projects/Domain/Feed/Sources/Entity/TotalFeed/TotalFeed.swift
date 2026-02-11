//
//  TotalFeed.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/29/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public struct TotalFeed: Equatable {
    
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
    
    public private(set) var thumbnailImageURL: ImageWrapper?
    public private(set) var imageCount: Int
    
    //MARK: - Policy
    
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
}
