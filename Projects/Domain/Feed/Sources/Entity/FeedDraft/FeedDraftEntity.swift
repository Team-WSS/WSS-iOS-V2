//
//  FeedDraftEntity.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// 피드를 작성 “초안 상태”를 표현하는 도메인 엔티티

public struct FeedDraftEntity {
    
    public let content: String
    public let genre: [NovelGenre]
    public let isSpoiler: Bool
    public let isPrivate: Bool
    public let connectedNovel: ConnectedNovel?
    public let attachedImageURLs: [URL]
    
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
