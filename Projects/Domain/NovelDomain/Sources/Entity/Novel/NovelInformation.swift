//
//  NovelInformation.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public struct NovelInformation {
    // 작품 기본 정보
    public let novel: Novel
    
    // 작품 부가 정보
    public let feedCount: Int
    public let genres: [NovelGenre]
    public let publicationStatus: NovelPublicationStatus
    
    // 작품에 대한 유저 평가
    public let userReview: UserNovelReview?
    
    // 작품 정보 탭
    public let description: String
    public let platforms: [NovelPlatform]
    public let attractivePoints: [AttractivePoint]
    public let keywords: [Keyword]
    public let readingStatusCount: [ReadingStatus : Int]
    
    public init(
        novel: Novel,
        feedCount: Int,
        genres: [NovelGenre],
        publicationStatus: NovelPublicationStatus,
        userReview: UserNovelReview?,
        description: String,
        platforms: [NovelPlatform],
        attractivePoints: [AttractivePoint],
        keywords: [Keyword],
        readingStatusCount: [ReadingStatus : Int]
    ) {
        self.novel = novel
        self.feedCount = feedCount
        self.genres = genres
        self.publicationStatus = publicationStatus
        self.userReview = userReview
        self.description = description
        self.platforms = platforms
        self.attractivePoints = attractivePoints
        self.keywords = keywords
        self.readingStatusCount = readingStatusCount
    }
    
    // MARK: - Policy
    
    static let dominantReadingStatusOrder: [ReadingStatus] = [
        .watching, .watched, .quit
    ]
    
    ///   - count가 모두 0이면 nil
    ///   - 최댓값이 동률이면 우선순위(watching → watched → quit)에 따라 결정
    public var dominantReadStatus: (status: ReadingStatus, count: Int)? {
        let positive = readingStatusCount.filter { $0.value > 0 }
        guard let maxCount = positive.values.max() else { return nil }
        
        return Self.dominantReadingStatusOrder
            .first(where: { positive[$0] == maxCount })
            .map { ($0, maxCount) }
    }
}
