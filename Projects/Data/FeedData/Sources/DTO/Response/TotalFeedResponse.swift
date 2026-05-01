//
//  TotalFeedResponse.swift
//  FeedData
//
//  Created by Lee Wonsun on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

struct TotalFeedResponse: Decodable {
    let userId: Int
    let nickname: String
    let avatarImage: String
    let feedId: Int
    let createdDate: String
    let feedContent: String
    let likeCount: Int
    let isLiked: Bool
    let commentCount: Int
    let novelId: Int?
    let title: String?
    let novelRatingCount: Int?
    let novelRating: Float?
    let relevantCategories: [String]
    let isSpoiler: Bool
    let isModified: Bool
    let isMyFeed: Bool
    let isPublic: Bool
    let thumbnailUrl: String?
    let imageCount: Int
    let genreName: String?
    let userNovelRating: Float?
    let feedWriterNovelRating: Float?
}
