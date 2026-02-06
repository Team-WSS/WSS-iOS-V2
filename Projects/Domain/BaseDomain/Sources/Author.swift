//
<<<<<<<< HEAD:Projects/Domain/BaseDomain/Sources/Author.swift
//  Author.swift
//  FeedDomain
========
//  FeedAuthor.swift
//  BaseDomain
>>>>>>>> 111d6aa ([Chore] #21 - BaseDomain 추가 및 FeedDomain에 의존성 주입):Projects/Domain/BaseDomain/Sources/FeedAuthor.swift
//
//  Created by Seoyeon Choi on 1/30/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct Author {
    
    public let userId: UserID
    public let nickname: String
    public let profileImage: ImageWrapper
    
    public init(
        userId: UserID,
        nickname: String,
        profileImage: ImageWrapper
    ) {
        self.userId = userId
        self.nickname = nickname
        self.profileImage = profileImage
    }
}
