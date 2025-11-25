//
//  NovelReviewResponse.swift
//  NovelReviewData
//
//  Created by YunhakLee on 11/25/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//


import Foundation

struct NovelReviewResponse: Codable {
    let novelTitle: String
    let status: String?
    let startDate: String?
    let endDate: String?
    let userNovelRating: Float
    let attractivePoints: [String]
    let keywords: [KeywordResponse]
}
