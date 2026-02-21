//
//  Novel.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public struct Novel {
    
    public let id: NovelID
    
    public let thumbnailImage: URL?
    public let title: String
    public let author: [String]?
    
    public private(set) var interestCount: Int?
    public let rating: Float?
    public let ratingCount: Int?
    public let feedCount: Int?
    
    public let genre: NovelGenre?
    public let publicationStatus: NovelPublicationStatus?
    
    public private(set) var isInterested: Bool?
}
