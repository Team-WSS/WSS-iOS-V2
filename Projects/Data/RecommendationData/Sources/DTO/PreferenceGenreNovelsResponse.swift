//
//  PreferenceGenreNovelsResponse.swift
//  RecommendationData
//
//  Created by Seoyeon Choi on 11/19/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//

import Foundation

//MARK: - 홈 - 선호 장르 기반 추천 웹소설

public struct PreferenceGenreNovelsResponse: Decodable {
    public let tasteNovels: [PreferenceGenreNovelResponse]
}

public struct PreferenceGenreNovelResponse: Decodable {
    public let novelId: Int
    public let title: String
    public let author: String
    public let novelImage: String
    public let interestCount: Int
    public let novelRating: Float
    public let novelRatingCount: Int
}
