//
//  UserFeedListResponse.swift
//  FeedData
//
//  Created by Lee Wonsun on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

struct UserFeedListResponse: Decodable {
    let isLoadable: Bool
    let feedsCount: Int
    let feeds: [UserFeedResponse]
}
