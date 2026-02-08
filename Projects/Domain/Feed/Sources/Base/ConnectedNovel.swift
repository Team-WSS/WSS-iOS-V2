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
    public private(set) var rating: Float?
}
