//
//  NovelInformationTests.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import NovelDomain
import NovelDomainTesting
import BaseDomain

@Suite
struct NovelInformationTests {

    // - 가장 많은 읽기 상태 반환
    
    @Test("readingStatusCount가 비어있으면 dominantReadStatus는 nil이다")
    func dominantReadStatus_emptyDictionary_returnsNil() {
        let info = makeNovelInformation(readingStatusCount: [:])

        #expect(info.dominantReadStatus == nil)
    }

    @Test("모든 count가 0이면 dominantReadStatus는 nil이다")
    func dominantReadStatus_allZero_returnsNil() {
        let info = makeNovelInformation(readingStatusCount: [
            .watching: 0,
            .watched: 0,
            .quit: 0
        ])

        #expect(info.dominantReadStatus == nil)
    }

    @Test("최댓값 count를 가진 읽기 상태를 반환한다")
    func dominantReadStatus_returnsMaxStatus() {
        let info = makeNovelInformation(readingStatusCount: [
            .watching: 3,
            .watched: 6,
            .quit: 4
        ])

        let dominant = info.dominantReadStatus
        #expect(dominant?.status == .watched)
        #expect(dominant?.count == 6)
    }

    @Test("동률이면 우선순위(watching → watched → quit)에 따라 결정한다")
    func dominantReadStatus_tieBreakByOrder() {
        let info = makeNovelInformation(readingStatusCount: [
            .watching: 6,
            .watched: 6,
            .quit: 4
        ])

        let dominant = info.dominantReadStatus
        #expect(dominant?.status == .watching)
        #expect(dominant?.count == 6)
    }

    @Test("동률이더라도 우선순위 상 앞선 값이 딕셔너리에 없으면 다음 우선순위를 선택한다")
    func dominantReadStatus_tieBreak_skipsMissingKey() {
        let info = makeNovelInformation(readingStatusCount: [
            .watched: 6,
            .quit: 6
            // .watching 없음
        ])

        let dominant = info.dominantReadStatus
        // watched가 quit보다 우선
        #expect(dominant?.status == .watched)
        #expect(dominant?.count == 6)
    }
}

extension NovelInformationTests {
    private func makeNovel() -> Novel {
        Novel(
            id: NovelID(1),
            thumbnailImage: nil,
            title: "전지적 독자 시점",
            author: ["싱숑"],
            interestCount: 100,
            rating: 4.5,
            ratingCount: 50,
            isInterested: nil
        )
    }

    private func makeNovelInformation(
        description: String = "재밌는 소설입니다.",
        platforms: [NovelPlatform] = [],
        attractivePoints: [AttractivePoint] = [],
        keywords: [Keyword] = [],
        readingStatusCount: [ReadingStatus: Int] = [:]
    ) -> NovelInformation {
        NovelInformation(
            novel: makeNovel(),
            feedCount: 4,
            genre: .BL,
            publicationStatus: .completed,
            userReview: nil,
            description: description,
            platforms: platforms,
            attractivePoints: attractivePoints,
            keywords: keywords,
            readingStatusCount: readingStatusCount
        )
    }
}
