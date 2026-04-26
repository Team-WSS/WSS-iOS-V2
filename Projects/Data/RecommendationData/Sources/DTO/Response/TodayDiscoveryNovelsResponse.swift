//
//  TodayDiscoveryNovelsResponse.swift
//  RecommendationData
//
//  Created by Seoyeon Choi on 11/19/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//

import Foundation

//MARK: - 홈 - 오늘의 발견

public struct TodayDiscoveryNovelsResponse: Decodable {
    public let popularNovels: [TodayDiscoveryNovelResponse]
}

public struct TodayDiscoveryNovelResponse: Decodable {
    public let novelId: Int
    public let title: String
    public let novelImage: String
    
    public let avatarImage: String?
    public let nickname: String?
    public let feedContent: String
}
