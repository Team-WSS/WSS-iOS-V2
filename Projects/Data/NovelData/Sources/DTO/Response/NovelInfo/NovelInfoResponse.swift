//
//  NovelInfoResponse.swift
//  NovelData
//
//  Created by Seoyeon Choi on 3/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct NovelInfoResponse: Decodable {
    public let novelDescription: String
    public let platforms: [NovelPlatformResponse]
    public let attractivePoints: [String]
    public let keywords: [NovelKeywordResponse]
    public let watchingCount: Int
    public let watchedCount: Int
    public let quitCount: Int
}
