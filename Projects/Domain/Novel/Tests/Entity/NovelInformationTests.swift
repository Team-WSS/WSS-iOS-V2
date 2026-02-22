//
//  NovelInformationTests.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import NovelDomain
@testable import BaseDomain

@Suite
struct NovelInformationTests {

    @Test("가장 많은 읽기 상태를 반환한다")
    func dominantReadStatusReturnsMax() throws {
        let info = makeInformation(readStatusCount: [
            .watching: 10,
            .watched: 30,
            .quit: 5
        ])

        let dominant = try info.dominantReadStatus()

        #expect(dominant?.status == .watched)
        #expect(dominant?.count == 30)
    }

    @Test("읽기 상태가 비어있으면 에러를 던진다")
    func dominantReadStatusThrowsWhenEmpty() {
        let info = makeInformation(readStatusCount: [:])

        #expect(throws: NovelInformation.ValidationError.emptyReadStatus) {
            try info.dominantReadStatus()
        }
    }

    @Test("읽기 상태가 하나만 있으면 해당 상태를 반환한다")
    func dominantReadStatusReturnsSingleStatus() throws {
        let info = makeInformation(readStatusCount: [.watching: 7])

        let dominant = try info.dominantReadStatus()

        #expect(dominant?.status == .watching)
        #expect(dominant?.count == 7)
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

    private func makeInformation(
        description: String = "재밌는 소설입니다.",
        platforms: [NovelPlatform] = [],
        attractivePoints: [AttractivePoint] = [],
        keywords: [Keyword] = [],
        readStatusCount: [ReadingStatus: Int] = [:]
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
            readStatusCount: readStatusCount
        )
    }
}
