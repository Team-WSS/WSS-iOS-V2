//
//  LibraryNovel.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public struct LibraryNovel {
    
    public let id: NovelID
    
    public let title: String
    public let thumbnailImage: URL?
    
    public let readStatus: ReadStatus?
    public let totalRating: Float?
    public let userRating: Rating?
    public let attractivePoint: [AttractivePoint]?
    public let readPeriod: ReadPeriod?
    public let keywords: [Keyword]?
    public let isInterested: Bool
    
    public let writtenFeeds: [String]
}
