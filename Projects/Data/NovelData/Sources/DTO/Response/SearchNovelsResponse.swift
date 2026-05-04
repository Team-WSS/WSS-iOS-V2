//
//  SearchNovelsResponse.swift
//  NovelData
//
//  Created by Seoyeon Choi on 3/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

// 일반탐색, 상세탐색 Reponse 형태 동일

public struct SearchNovelsResponse: Decodable {
    public let resultCount: Int
    public let isLoadable: Bool
    public let novels: [SearchNovelResponse]
}

public struct SearchNovelResponse: Decodable {
    public let novelId: Int
    public let novelImage: String
    public let title: String
    public let author: String
    public let interestCount: Int
    public let novelRating: Float
    public let novelRatingCount: Int
}
