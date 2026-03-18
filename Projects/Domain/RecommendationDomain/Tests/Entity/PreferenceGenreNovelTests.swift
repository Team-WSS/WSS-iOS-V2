//
//  PreferenceGenreNovelTests.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import RecommendationDomain
import RecommendationDomainTesting
import BaseDomain

@Suite
struct PreferenceGenreNovelTests {

    // MARK: - Helpers

    private func makePreferenceGenreNovel(
        novelID: NovelID = NovelID(1),
        novelTitle: String = "추천 소설",
        novelAuthors: [String] = ["작가명"],
        interestCount: Int = 50,
        ratingCount: Int = 200,
        rating: Float = 2.0
    ) -> PreferenceGenreNovel {
        PreferenceGenreNovel(
            novelID: novelID,
            novelTitle: novelTitle,
            novelThumbnailImage: nil,
            novelAuthors: novelAuthors,
            interestCount: interestCount,
            ratingCount: ratingCount,
            rating: rating
        )
    }

    // MARK: - novels 상태

    @Test("novels 상태에서 소설 목록을 확인할 수 있다")
    func novelsStateContainsNovelList() {
        let novel = makePreferenceGenreNovel(novelTitle: "판타지 소설")
        let state = PreferenceGenreNovelState.novels([novel])

        guard case .novels(let novels) = state else {
            Issue.record("novels 상태여야 합니다")
            return
        }

        #expect(novels.count == 1)
        #expect(novels.first?.novelTitle == "판타지 소설")
    }

    @Test("novels 상태에서 여러 소설을 포함할 수 있다")
    func novelsStateCanContainMultipleNovels() {
        let novels = [makePreferenceGenreNovel(),
                      makePreferenceGenreNovel(),
                      makePreferenceGenreNovel()]
        let state = PreferenceGenreNovelState.novels(novels)

        guard case .novels(let result) = state else {
            Issue.record("novels 상태여야 합니다")
            return
        }

        #expect(result.count == 3)
    }

    @Test("novels 상태에서 소설 목록이 비어있을 수 있다")
    func novelsStateCanBeEmpty() {
        let state = PreferenceGenreNovelState.novels([])

        guard case .novels(let novels) = state else {
            Issue.record("novels 상태여야 합니다")
            return
        }

        #expect(novels.isEmpty)
    }

    // MARK: - 비활성 상태

    @Test("선호 장르가 미설정된 상태를 표현할 수 있다")
    func canRepresentNoGenreSettingsState() {
        let state = PreferenceGenreNovelState.noGenreSettings

        var isMatch = false
        if case .noGenreSettings = state { isMatch = true }

        #expect(isMatch)
    }

    // MARK: - PreferenceGenreNovel 속성

    @Test("소설에 여러 저자를 담을 수 있다")
    func novelCanContainMultipleAuthors() {
        let authors = ["작가A", "작가B", "작가C"]
        let novel = makePreferenceGenreNovel(novelAuthors: authors)

        #expect(novel.novelAuthors.count == 3)
        #expect(novel.novelAuthors == authors)
    }

    @Test("소설의 관심 수와 평가 수를 포함한다")
    func novelIncludesInterestAndRatingCount() {
        let novel = makePreferenceGenreNovel(interestCount: 123, ratingCount: 456)

        #expect(novel.interestCount == 123)
        #expect(novel.ratingCount == 456)
    }

    @Test("소설의 평점을 포함한다")
    func novelIncludesRating() {
        let novel = makePreferenceGenreNovel(rating: 4.5)

        #expect(novel.rating == 4.5)
    }

    @Test("평점이 0일 수 있다")
    func ratingCanBeZero() {
        let novel = makePreferenceGenreNovel(rating: 0.0)

        #expect(novel.rating == 0.0)
    }
}
