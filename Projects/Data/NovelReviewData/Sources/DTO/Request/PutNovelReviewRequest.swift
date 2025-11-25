//
//  PutNovelReviewRequest.swift
//  NovelReviewData
//
//  Created by YunhakLee on 11/25/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//


import Foundation
import Networking

struct PutNovelReviewRequest: RequestBodyConvertible {
    let userNovelRating: Float
    let status: String
    let startDate: String?
    let endDate: String?
    let attractivePoints: [String]
    let keywordIds: [Int]
}
