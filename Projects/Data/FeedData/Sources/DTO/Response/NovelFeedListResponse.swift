//
//  NovelFeedListResponse.swift
//  FeedData
//
//  Created by Lee Wonsun on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

struct NovelFeedListResponse: Decodable {
    let isLoadable: Bool
    let feeds: [NovelFeedResponse]
}
