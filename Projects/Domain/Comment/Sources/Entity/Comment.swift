//
//  Comment.swift
//  CommentDomain
//
//  Created by Seoyeon Choi on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public struct Comment {
    
    public let id: CommentID
    
    public private(set) var user: Author
    public private(set) var createdDate: String
    public private(set) var content: String
    
    public private(set) var isModified: Bool
    
    public private(set) var isSpoiler: Bool
    public private(set) var isBlocked: Bool
    public private(set) var isHidden: Bool
    
    //MARK: - Custom Properties
    
    public func isMyComment(_ myID: UserID) -> Bool {
        user.userId == myID
    }
    
    //MARK: - Policy
    
    
}
