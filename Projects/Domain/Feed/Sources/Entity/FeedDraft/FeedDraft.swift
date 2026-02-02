//
//  FeedDraft.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// 피드를 작성 “초안 상태”를 표현하는 도메인 엔티티

public struct FeedDraft {
    
    public private(set) var content: String
    public private(set) var genre: [NovelGenre]
    public private(set) var isSpoiler: Bool
    public private(set) var isPrivate: Bool
    public private(set) var connectedNovel: ConnectedNovel?
    public private(set) var attachedImageURLs: [URL]
    
    public init(content: String,
                genre: [NovelGenre],
                isSpoiler: Bool,
                isPrivate: Bool,
                connectedNovel: ConnectedNovel?,
                attachedImageURLs: [URL]) {
        self.content = content
        self.genre = genre
        self.isSpoiler = isSpoiler
        self.isPrivate = isPrivate
        self.connectedNovel = connectedNovel
        self.attachedImageURLs = attachedImageURLs
    }
}
