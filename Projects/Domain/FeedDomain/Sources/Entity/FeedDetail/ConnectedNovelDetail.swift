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
    public let thumbnailImageURL: URL?
    public let descirption: String
    public private(set) var feedWriterRating: Float?

    public init(
        basicInfo: ConnectedNovel,
        thumbnailImageURL: URL?,
        descirption: String,
        feedWriterRating: Float? = nil
    ) {
        self.basicInfo = basicInfo
        self.thumbnailImageURL = thumbnailImageURL
        self.descirption = descirption
        self.feedWriterRating = feedWriterRating
    }
    
}
