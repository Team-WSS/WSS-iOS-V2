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
    let novelId: Int?
    let isSpoiler: Bool
    let isPublic: Bool
    let imageDatas: [Data]
}
