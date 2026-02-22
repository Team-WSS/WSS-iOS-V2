//
//  UserNovelReview.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct UserNovelReview {
    public let rating: Rating?
    public let readStatus: ReadStatus?
    public let attractivePoint: [AttractivePoint]
    public let period: ReadingPeriod?
    public let keywords: [Keyword]
}
