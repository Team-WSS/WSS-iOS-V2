//
//  ConnectedNovelDetail.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/29/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct ConnectedNovelDetail {
    
    public private(set) var basicInfo: ConnectedNovel
    public private(set) var thumbnailImage: URL?
    public private(set) var descirption: String
    public private(set) var totalRating: Float
    public private(set) var feedWriterRating: Float?
}
