//
//  SosoPickTests.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
import Foundation
@testable import RecommendationDomain
@testable import BaseDomain

@Suite
struct SosoPickTests {

    // MARK: - Helpers

    private func makeSosoPick(
        novelID: NovelID = NovelID(1),
        novelTitle: String = "소소 픽 소설",
        novelThumbnailimage: URL? = nil
    ) -> SosoPick {
        SosoPick(
            novelID: novelID,
            novelTitle: novelTitle,
            novelThumbnailimage: novelThumbnailimage
        )
    }

    // MARK: - Tests

    @Test func `소소픽을 생성할 수 있다.`() {
        let pick = makeSosoPick(novelID: NovelID(42), novelTitle: "추천 소설")

        #expect(pick.novelID == NovelID(42))
        #expect(pick.novelTitle == "추천 소설")
    }

    @Test func `썸네일 이미지를 포함하여 생성할 수 있다.`() {
        let url = URL(string: "https://example.com/thumbnail.jpg")
        let pick = makeSosoPick(novelThumbnailimage: url)

        #expect(pick.novelThumbnailimage != nil)
    }
}
