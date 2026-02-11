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

    @Test func `가장 많은 읽기 상태를 반환한다.`() throws {
        let info = makeInformation(readStatusCount: [
            .watching: 10,
            .watched: 30,
            .quit: 5
        ])

        let dominant = try info.dominantReadStatus()

        #expect(dominant?.status == .watched)
        #expect(dominant?.count == 30)
    }

    @Test func `읽기 상태가 비어있으면 에러를 던진다.`() {
        let info = makeInformation(readStatusCount: [:])

        #expect(throws: NovelInformation.ValidationError.emptyReadStatus) {
            try info.dominantReadStatus()
        }
    }

    @Test func `읽기 상태가 하나만 있으면 해당 상태를 반환한다.`() throws {
        let info = makeInformation(readStatusCount: [.watching: 7])

        let dominant = try info.dominantReadStatus()

        #expect(dominant?.status == .watching)
        #expect(dominant?.count == 7)
    }
}

extension NovelInformationTests {
    private func makeInformation(
        description: String = "재밌는 소설입니다.",
        platforms: [NovelPlatform] = [],
        attractivePoints: [AttractivePoint] = [],
        keywords: [Keyword] = [],
        readStatusCount: [ReadStatus: Int] = [:]
    ) -> NovelInformation {
        NovelInformation(
            description: description,
            platforms: platforms,
            attractivePoints: attractivePoints,
            keywords: keywords,
            readStatusCount: readStatusCount
        )
    }
}
