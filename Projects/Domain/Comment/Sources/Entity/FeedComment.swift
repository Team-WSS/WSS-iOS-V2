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
}
