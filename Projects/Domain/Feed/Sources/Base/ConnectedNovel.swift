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
    public let title: String
    public let genre: NovelGenre
    public let rating: Float?
    
    public init(id: NovelID,
                title: String,
                genre: NovelGenre,
                rating: Float) {
        self.id = id
        self.title = title
        self.genre = genre
        self.rating = rating
    }
}
