//
//  ConnectedNovelDetail.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/29/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct ConnectedNovelDetail {
    public let basicInfo: ConnectedNovel
    public let thumbnailImage: URL?
    public let descirption: String
    public let totalRating: Float
    public let feedWriterRating: Float?
    
    public init(basicInfo: ConnectedNovel,
                thumbnailImage: URL?,
                descirption: String,
                totalRating: Float,
                feedWriterRating: Float?) {
        self.basicInfo = basicInfo
        self.thumbnailImage = thumbnailImage
        self.descirption = descirption
        self.totalRating = totalRating
        self.feedWriterRating = feedWriterRating
    }
}
