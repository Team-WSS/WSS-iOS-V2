//
//  FeedAuthor.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/30/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct FeedAuthor {
    
    public let userId: UserID
    public let nickname: String
    public let avatarImageURL: URL?
    
    public init(
        userId: UserID,
        nickname: String,
        avatarImageURL: URL?
    ) {
        self.userId = userId
        self.nickname = nickname
        self.avatarImageURL = avatarImageURL
    }
}
