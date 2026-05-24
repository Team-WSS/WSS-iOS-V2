//
//  SubmitFeedRequest.swift
//  FeedData
//
//  Created by Lee Wonsun on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

struct SubmitFeedRequest: Encodable {
    let feedContent: String
    let relevantCategories: [String]
    let novelId: Int?
    let isSpoiler: Bool
    let isPublic: Bool
    let imageDatas: [Data]

    enum CodingKeys: String, CodingKey {
        case feedContent
        case relevantCategories
        case novelId
        case isSpoiler
        case isPublic
        // imageDatas는 multipart의 images part로 별도 전송되므로 직렬화 제외
    }
}
