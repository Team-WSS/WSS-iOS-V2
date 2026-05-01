//
//  ConnectedNovelDetail.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/29/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public struct ConnectedNovelDetail {
    
    public let basicInfo: ConnectedNovel
    public let thumbnailImage: ImageWrapper
    public let descirption: String
    public private(set) var feedWriterRating: Float?
    
    public init(
        basicInfo: ConnectedNovel,
        thumbnailImage: ImageWrapper,
        descirption: String,
        feedWriterRating: Float? = nil
    ) {
        self.basicInfo = basicInfo
        self.thumbnailImage = thumbnailImage
        self.descirption = descirption
        self.feedWriterRating = feedWriterRating
    }
    
}
