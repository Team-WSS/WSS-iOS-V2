//
//  BlockedUserResponse.swift
//  SocialData
//
//  Created by YunhakLee on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

struct BlockedUserResponse: Decodable {
    let blocks: [BlockdUser]
}

struct BlockdUser: Decodable {
    let blockId: Int
    let userId: Int
    let nickname: String
    let avatarImage: String
}
