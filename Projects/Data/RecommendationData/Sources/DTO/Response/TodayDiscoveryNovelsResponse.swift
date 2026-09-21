//
//  TodayDiscoveryNovelsResponse.swift
//  RecommendationData
//
//  Created by Seoyeon Choi on 11/19/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//

import Foundation

//MARK: - 홈 - 오늘의 발견

struct TodayDiscoveryNovelsResponse: Decodable {
    public let popularNovels: [TodayDiscoveryNovelResponse]
}

struct TodayDiscoveryNovelResponse: Decodable {
    public let novelId: Int
    public let title: String
    public let novelImage: String
    public let author: String
    public let genreName: String
    public let isNovelCompleted: Bool
    public let keywords: [String]

    /// 작품 소개글. 유저 한마디가 없는 카드의 본문이 된다.
    public let novelDescription: String

    /// 셋 다 유저 한마디 카드에서만 채워진다(작품 소개 카드는 nickname·avatarImage가 null).
    public let avatarImage: String?
    public let nickname: String?
    public let feedContent: String?
}
