//
//  NovelPreferenceResponse.swift
//  ProfileData
//
//  Created by WonsunLee on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

struct NovelPreferenceResponse: Decodable {
    let attractivePoints: [String]
    let keywords: [KeywordPreferenceResponse]
}

struct KeywordPreferenceResponse: Decodable {
    let keywordName: String
    let keywordCount: Int
}
