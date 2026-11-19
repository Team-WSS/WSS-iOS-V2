//
//  NovelInformationTests.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

import BaseDomain
import NovelDomain

@Suite("작품 상세의 대표 독서 상태")
struct NovelInformationTests {

    @Test(
        "읽은 사람이 없으면 대표 독서 상태가 없다",
        arguments: [
            [:],                                   // 독서 상태 수가 비어 있음
            [.watching: 0, .watched: 0, .quit: 0]  // 모두 0명
        ] as [[ReadingStatus: Int]]
    )
    func noDominantStatusWithoutReaders(readingStatusCount: [ReadingStatus: Int]) {
        let information = makeNovelInformation(readingStatusCount: readingStatusCount)

        let dominant = information.dominantReadStatus

        #expect(dominant == nil)
    }

    @Test("가장 많이 고른 독서 상태가 대표가 된다")
    func mostChosenStatusIsDominant() {
        let information = makeNovelInformation(readingStatusCount: [.watching: 3, .watched: 6, .quit: 4])

        let dominant = information.dominantReadStatus

        #expect(dominant?.status == .watched)
        #expect(dominant?.count == 6)
    }

    @Test(
        "수가 같으면 보는 중, 봤음, 하차 순으로 대표를 정한다",
        arguments: [
            ([.watching: 6, .watched: 6, .quit: 4], .watching),  // 보는 중 = 봤음이면 보는 중
            ([.watching: 2, .watched: 6, .quit: 6], .watched)    // 봤음 = 하차면 봤음
        ] as [([ReadingStatus: Int], ReadingStatus)]
    )
    func tieFollowsStatusOrder(readingStatusCount: [ReadingStatus: Int], expected: ReadingStatus) {
        let information = makeNovelInformation(readingStatusCount: readingStatusCount)

        let dominant = information.dominantReadStatus

        #expect(dominant?.status == expected)
        #expect(dominant?.count == 6)
    }
}

private func makeNovelInformation(readingStatusCount: [ReadingStatus: Int]) -> NovelInformation {
    NovelInformation(
        novel: Novel(
            id: NovelID(1),
            thumbnailImage: nil,
            title: "전지적 독자 시점",
            authors: ["싱숑"],
            genres: [.fantasy],
            interestCount: 100,
            rating: 4.5,
            ratingCount: 50,
            isInterested: nil
        ),
        feedCount: 4,
        publicationStatus: .completed,
        userReview: nil,
        description: "재밌는 소설입니다.",
        platforms: [],
        attractivePoints: [],
        keywords: [],
        readingStatusCount: readingStatusCount
    )
}
