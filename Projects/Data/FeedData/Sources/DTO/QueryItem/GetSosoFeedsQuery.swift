//
//  GetSosoFeedsQuery.swift
//  FeedData
//
//  Created by Lee Wonsun on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//
import Networking

struct GetSosoFeedsQuery: QueryItemConvertible {
    let category: String?
    let lastFeedId: Int
    let size: Int
    let option: String
}
