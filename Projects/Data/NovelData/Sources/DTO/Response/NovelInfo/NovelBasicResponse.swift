//
//  NovelBasicResponse.swift
//  NovelData
//
//  Created by Seoyeon Choi on 3/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

struct NovelBasicResponse: Decodable {
    public let userNovelId: Int?
    public let novelTitle: String
    public let novelImage: String
    /// 서버는 장르를 `"로맨스/로판"`처럼 **`/`로 이은 한 문자열**로 준다(배열 아님).
    public let novelGenres: String
    public let novelGenreImage: String
    public let isNovelCompleted: Bool
    public let author: String
    public let interestCount: Int
    public let novelRating: Float
    public let novelRatingCount: Int
    public let feedCount: Int
    public let userNovelRating: Float
    public let readStatus: String?
    public let startDate: String?
    public let endDate: String?
    public let isUserNovelInterest: Bool
}
