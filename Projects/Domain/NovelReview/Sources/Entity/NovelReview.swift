//
//  NovelReview.swift
//  NovelReviewDomain
//
//  Created by YunhakLee on 1/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Foundation

public struct NovelReview: Hashable, Equatable {
    public let novelID: NovelID

    public let status: ReadingStatus
    public let period: ReadingPeriod?

    public let rating: Rating?
    public let charmPoints: [CharmPoint]
    public let keywords: [Keyword]

    public init(
        novelID: NovelID,
        status: ReadingStatus,
        period: ReadingPeriod?,
        rating: Rating?,
        charmPoints: [CharmPoint],
        keywords: [Keyword]
    ) {
        self.novelID = novelID
        self.status = status
        self.period = period
        self.rating = rating
        self.charmPoints = charmPoints
        self.keywords = keywords
    }
}
