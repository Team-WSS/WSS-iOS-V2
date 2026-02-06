//
//  ConnectedNovel.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct ConnectedNovel {
    
    public let id: NovelID
    
    public private(set) var title: String
    public private(set) var genre: NovelGenre
    public private(set) var rating: Float?
    
    //MARK: - Policy
    
    public mutating func roundedRating() {
        if let novelRating = rating {
            rating = round(novelRating * 10) / 10
        }
    }
}
