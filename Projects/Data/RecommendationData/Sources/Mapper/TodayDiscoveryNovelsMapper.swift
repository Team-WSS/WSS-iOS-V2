//
//  TodayDiscoveryNovelsMapper.swift
//  RecommendationData
//
//  Created by Seoyeon Choi on 11/19/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//

import Foundation

import RecommendationDomain
import BaseDomain

extension TodayDiscoveryNovelsResponse {
    public func toEntity() -> [TodayDiscovery] {
        return self.discoveries.map { $0.toEntity() }
    }
}

extension TodayDiscoveryNovelResponse {
    public func toEntity() -> TodayDiscovery {
        let novelImageURL = URL(string: self.novelImage)
        let isNovelIntroduction = (self.nickname == nil || self.avatarImage == nil)
        
        let content: TodayDiscovery.Content
        if isNovelIntroduction {
            content = .novel
        } else {
            let profileImageURL = URL(string: self.avatarImage ?? "")
            let author = Author(nickname: self.nickname ?? "웹소소",
                                profileImage: profileImageURL)
            content = .userComment(user: author)
        }
        
        return TodayDiscovery(
            novelID: NovelID(self.novelId),
            novelTitle: self.title,
            novelThumbnailImage: novelImageURL,
            content: content,
            contentDescription: self.feedContent
        )
    }
}
