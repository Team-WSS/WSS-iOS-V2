//
//  SosopickNovelsMapper.swift
//  RecommendationData
//
//  Created by Seoyeon Choi on 11/19/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//

import Foundation

import RecommendationDomain
import BaseDomain

extension SosopickNovelsResponse {
    public func toEntity() -> [SosoPick] {
        return self.sosoPicks.map { $0.toEntity() }
    }
}

extension SosopickNovelResponse {
    public func toEntity() -> SosoPick {
        let imageURL = URL(string: self.novelImage)
        
        return SosoPick(
            novelID: NovelID(self.novelId),
            novelTitle: self.title,
            novelThumbnailimage: imageURL
        )
    }
}
