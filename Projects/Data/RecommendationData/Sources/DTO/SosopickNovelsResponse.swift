//
//  SosopickNovelsResponse.swift
//  RecommendationData
//
//  Created by Seoyeon Choi on 11/19/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//

import Foundation

//MARK: - 탐색 - 소소픽 웹소설

public struct SosopickNovelsResponse: Decodable {
    public let sosoPicks: [SosopickNovelResponse]
}

public struct SosopickNovelResponse: Decodable {
    public let novelId: Int
    public let novelImage: String
    public let title: String
}
