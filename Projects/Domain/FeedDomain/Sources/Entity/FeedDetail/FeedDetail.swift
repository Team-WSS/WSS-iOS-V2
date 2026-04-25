//
//  FeedDetail.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/29/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public struct FeedDetail {
    
    public let id: FeedID
    public let author: Author
    public let createdDate: String
    
    public private(set) var isModified: Bool
    
    public private(set) var feedContent: String
    public private(set) var feedImageURLs: [ImageWrapper?]
    
    public private(set) var connectedNovel: ConnectedNovelDetail?
    
    public private(set) var likeCount: Int
    public private(set) var isLiked: Bool
    public private(set) var commentCount: Int
    
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
}
