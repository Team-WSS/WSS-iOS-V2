//
//  SubmitFeedRequest.swift
//  FeedData
//
//  Created by Lee Wonsun on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

struct SubmitFeedRequest: Encodable {
    let feedContent: String
    let relevantCategories: [String]
    let novelId: Int?
    let isSpoiler: Bool
    let isPublic: Bool
}
