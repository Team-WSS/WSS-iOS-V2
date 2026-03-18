//
//  SosoPick.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public struct SosoPick {
    
    public let novelID: NovelID
    
    public let novelTitle: String
    public let novelThumbnailimage: URL?
    
    public init(
        novelID: NovelID,
        novelTitle: String,
        novelThumbnailimage: URL?
    ) {
        self.novelID = novelID
        self.novelTitle = novelTitle
        self.novelThumbnailimage = novelThumbnailimage
    }
}
