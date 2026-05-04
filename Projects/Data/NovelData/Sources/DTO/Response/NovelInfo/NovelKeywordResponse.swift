//
//  NovelKeywordResponse.swift
//  NovelData
//
//  Created by Seoyeon Choi on 3/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct NovelKeywordResponse: Decodable {
    public let keywordName: String
    public let keywordCount: Int
}
