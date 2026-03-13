//
//  UserNovelReview.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

// 서재 / 작품상세에서 사용되는 작품 평가 엔티티
public struct UserNovelReview {
    public let readingStatus: ReadingStatus
    public let rating: Rating?
    public let attractivePoint: [AttractivePoint]
    public let period: ReadingPeriod?
    public let keywords: [Keyword]
}
