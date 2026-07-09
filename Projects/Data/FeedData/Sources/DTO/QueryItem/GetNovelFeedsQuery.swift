//
//  GetNovelFeedsQuery.swift
//  FeedData
//
//  Created by YunhakLee on 7/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Networking

struct GetNovelFeedsQuery: QueryItemConvertible {
    let lastFeedId: Int
    let size: Int
}
