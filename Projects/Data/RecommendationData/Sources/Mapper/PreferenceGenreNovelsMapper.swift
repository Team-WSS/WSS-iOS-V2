//
//  PreferenceGenreNovelsMapper.swift
//  RecommendationData
//
//  Created by Seoyeon Choi on 11/19/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//

import Foundation

import RecommendationDomain
import BaseDomain

extension PreferenceGenreNovelsResponse {
    public func toEntity() -> [PreferenceGenreNovel] {
        return self.tasteNovels.map { $0.toEntity() }
    }
}

extension PreferenceGenreNovelResponse {
    public func toEntity() -> PreferenceGenreNovel {
        let novelImageURL = URL(string: self.novelImage)
        let novelAuthorArray: [String] = self.author.components(separatedBy: ",")
 
        return PreferenceGenreNovel(
            novelID: NovelID(self.novelId),
            novelTitle: self.title,
            novelThumbnailImage: novelImageURL,
            novelAuthors: novelAuthorArray,
            interestCount: self.interestCount,
            ratingCount: self.novelRatingCount,
            rating: self.novelRating
        )
    }
}
