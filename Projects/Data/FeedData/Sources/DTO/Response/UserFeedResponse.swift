//
//  UserFeedResponse.swift
//  FeedData
//
//  Created by Lee Wonsun on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

struct UserFeedResponse: Decodable {
    let feedId: Int
    let feedContent: String
    let createdDate: String
    let isSpoiler: Bool
    let isModified: Bool
    let likeUsers: [Int]
    let isLiked: Bool
    let likeCount: Int
    let commentCount: Int
    let novelId: Int?
    let title: String?
    let novelRating: Float?
    let novelRatingCount: Int?
    let relevantCategories: [String]
    let isPublic: Bool
    let genre: String?
    let userNovelRating: Float?
    let thumbnailUrl: String?
    let imageCount: Int
    let feedWriterNovelRating: Float?
}
