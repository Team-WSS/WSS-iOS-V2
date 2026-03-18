//
//  Author.swift
//  BaseDomain
//
//  Created by Seoyeon Choi on 1/30/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct Author {
    
    public let userId: UserID?
    public let nickname: String
    public let profileImage: URL?
    
    public init(
        userId: UserID? = nil,
        nickname: String,
        profileImage: URL?
    ) {
        self.userId = userId
        self.nickname = nickname
        self.profileImage = profileImage
    }
}
