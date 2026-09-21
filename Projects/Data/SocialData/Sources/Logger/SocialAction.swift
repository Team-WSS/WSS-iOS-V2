//
//  SocialAction.swift
//  SocialData
//
//  Created by Lee Wonsun on 4/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

enum SocialAction: String {
    case blockUser
    case unblockUser
    case loadBlockedUsers
    case reportSpoilerFeed
    case reportImproperFeed
    case reportSpoilerComment
    case reportImproperComment
    
    var name: String { return self.rawValue }
}
