//
//  SocialMapper.swift
//  SocialData
//
//  Created by YunhakLee on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import SocialDomain
import BaseDomain

enum SocialMapper {

    static func blockedUser(from response: BlockdUser) -> BlockedUser {
        BlockedUser(
            blockID: BlockID(response.blockId),
            userID: UserID(response.userId),
            nickname: response.nickname,
            profileImageURL: URL(string: response.avatarImage)
        )
    }

    static func blockedUsers(from response: BlockedUserResponse) -> [BlockedUser] {
        response.blocks.map { blockedUser(from: $0) }
    }
}
