//
//  FeedComment.swift
//  CommentDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public struct FeedComment {
    
    public let id: CommentID
    
    public let user: Author
    public let createdDate: String
    public let content: String
    
    public private(set) var isModified: Bool

    public private(set) var isSpoiler: Bool
    public private(set) var isBlocked: Bool
    public private(set) var isHidden: Bool
    
    public init(
        id: CommentID,
        user: Author,
        createdDate: String,
        content: String,
        isModified: Bool,
        isSpoiler: Bool,
        isBlocked: Bool,
        isHidden: Bool
    ) {
        self.id = id
        self.user = user
        self.createdDate = createdDate
        self.content = content
        self.isModified = isModified
        self.isSpoiler = isSpoiler
        self.isBlocked = isBlocked
        self.isHidden = isHidden
    }
}
