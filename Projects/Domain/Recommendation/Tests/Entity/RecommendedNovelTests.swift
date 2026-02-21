//
//  RecommendedNovelTests.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import RecommendationDomain
@testable import BaseDomain

@Suite
struct RecommendedNovelTests {

    // MARK: - Helpers

    private func makeRecommendedNovel(
        novelID: NovelID = NovelID(1),
        novelTitle: String = "추천 소설",
        novelAuthors: [String] = ["작가명"],
        interestCount: Int = 50,
        ratingCount: Int = 200
    ) -> RecommendedNovel {
        RecommendedNovel(
            novelID: novelID,
            novelTitle: novelTitle,
            novelThumbnailImage: nil,
            novelAuthors: novelAuthors,
            interestCount: interestCount,
            ratingCount: ratingCount
        )
    }

    // MARK: - novels 상태

    @Test func `novels 상태에서 소설 목록을 확인할 수 있다.`() {
        let novel = makeRecommendedNovel(novelTitle: "판타지 소설")
        let state = RecommendedNovelState.novels([novel])

        guard case .novels(let novels) = state else {
            Issue.record("novels 상태여야 합니다")
            return
        }

        #expect(novels.count == 1)
        #expect(novels.first?.novelTitle == "판타지 소설")
    }

    @Test func `novels 상태에서 여러 소설을 포함할 수 있다.`() {
        let novels = [makeRecommendedNovel(), makeRecommendedNovel(), makeRecommendedNovel()]
        let state = RecommendedNovelState.novels(novels)

        guard case .novels(let result) = state else {
            Issue.record("novels 상태여야 합니다")
            return
        }

        #expect(result.count == 3)
    }

    @Test func `novels 상태에서 소설 목록이 비어있을 수 있다.`() {
        let state = RecommendedNovelState.novels([])

        guard case .novels(let novels) = state else {
            Issue.record("novels 상태여야 합니다")
            return
        }

        #expect(novels.isEmpty)
    }

    // MARK: - 비활성 상태

    @Test func `선호 장르가 미설정된 상태를 표현할 수 있다.`() {
        let state = RecommendedNovelState.noGenreSettings

        var isMatch = false
        if case .noGenreSettings = state { isMatch = true }

        #expect(isMatch)
    }

    // MARK: - RecommendedNovel 속성

    @Test func `소설에 여러 저자를 담을 수 있다.`() {
        let authors = ["작가A", "작가B", "작가C"]
        let novel = makeRecommendedNovel(novelAuthors: authors)

        #expect(novel.novelAuthors.count == 3)
        #expect(novel.novelAuthors == authors)
    }

    @Test func `소설의 관심 수와 평가 수를 포함한다.`() {
        let novel = makeRecommendedNovel(interestCount: 123, ratingCount: 456)

        #expect(novel.interestCount == 123)
        #expect(novel.ratingCount == 456)
    }
}
