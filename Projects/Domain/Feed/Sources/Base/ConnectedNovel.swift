//
//  ConnectedNovel.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct ConnectedNovel {
    public let id: Int
    public let title: String
    public let genre: NovelGenre
    
    public init(id: Int,
                title: String,
                genre: NovelGenre) {
        self.id = id
        self.title = title
        self.genre = genre
    }
}
