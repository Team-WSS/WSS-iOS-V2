//
//  GetUserFeedsQuery.swift
//  FeedData
//
//  Created by Lee Wonsun on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Networking

struct GetUserFeedsQuery: QueryItemConvertible {
    let lastFeedID: Int
    let size: Int
    let isVisible: Bool?
    let isUnVisible: Bool?
    let genreNames: [String]?
    let sortCriteria: String?
}
