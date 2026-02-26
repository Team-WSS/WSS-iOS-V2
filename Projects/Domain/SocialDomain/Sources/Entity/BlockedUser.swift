//
//  BlockedUser.swift
//  SocialDomain
//
//  Created by YunhakLee on 2/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public struct BlockedUser: Equatable {
    public let blockId: BlockID
    public let userID: UserID
    public let nickname: String
    public let profileImageURL: URL?
}
