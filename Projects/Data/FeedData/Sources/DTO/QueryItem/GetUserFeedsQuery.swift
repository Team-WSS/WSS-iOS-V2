//
//  GetUserFeedsQuery.swift
//  FeedData
//
//  Created by Lee Wonsun on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

struct GetUserFeedsQuery {
    let lastFeedID: Int
    let size: Int
    let isVisible: Bool?
    let isUnVisible: Bool?
    let genreNames: [String]?
    let sortCriteria: String?
}
