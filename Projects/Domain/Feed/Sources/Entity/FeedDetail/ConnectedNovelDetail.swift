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
    public let thumbnailImage: ImageWrapper
    public let descirption: String
    public private(set) var feedWriterRating: Float?
    
}
