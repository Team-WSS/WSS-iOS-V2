//
//  NovelSearchFilterTests.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import NovelDomain
@testable import BaseDomain

@Suite
struct NovelSearchFilterTests {

    // MARK: - Genre

    @Test("장르를 추가할 수 있다")
    func addGenre() {
        var filter = makeFilter()

        filter.addGenre(.fantasy)

        #expect(filter.genres == [.fantasy])
    }

    @Test("이미 추가된 장르는 중복 추가되지 않는다")
    func addGenreDuplicate() {
        var filter = makeFilter(genres: [.fantasy])

        filter.addGenre(.fantasy)

        #expect(filter.genres == [.fantasy])
    }

    @Test("장르를 제거할 수 있다")
    func removeGenre() {
        var filter = makeFilter(genres: [.fantasy, .romance])

        filter.removeGenre(.fantasy)

        #expect(filter.genres == [.romance])
    }

    @Test("장르를 전체 초기화할 수 있다")
    func clearGenres() {
        var filter = makeFilter(genres: [.fantasy, .romance, .BL])

        filter.clearGenres()

        #expect(filter.genres.isEmpty)
    }

    // MARK: - Publication Status

    @Test("출판 상태를 설정할 수 있다")
    func setPublicationStatus() {
        var filter = makeFilter()

        filter.setPublicationStatus(.completed)

        #expect(filter.publicationStatus == .completed)
    }

    @Test("같은 출판 상태를 다시 설정하면 해제된다")
    func setPublicationStatusToggle() {
        var filter = makeFilter()

        filter.setPublicationStatus(.completed)
        filter.setPublicationStatus(.completed)

        #expect(filter.publicationStatus == nil)
    }

    @Test("다른 출판 상태를 설정하면 변경된다")
    func setPublicationStatusChange() {
        var filter = makeFilter()

        filter.setPublicationStatus(.completed)
        filter.setPublicationStatus(.onGoing)

        #expect(filter.publicationStatus == .onGoing)
    }

    @Test("출판 상태를 초기화할 수 있다")
    func clearPublicationStatus() {
        var filter = makeFilter()
        filter.setPublicationStatus(.completed)

        filter.clearPublicationStatus()

        #expect(filter.publicationStatus == nil)
    }

    // MARK: - Rating Threshold

    @Test("별점 기준을 설정할 수 있다")
    func setRatingThreshold() {
        var filter = makeFilter()

        filter.setRatingThreshold(.over4_0)

        #expect(filter.ratingThreshold == .over4_0)
    }

    @Test("같은 별점 기준을 다시 설정하면 해제된다")
    func setRatingThresholdToggle() {
        var filter = makeFilter()

        filter.setRatingThreshold(.over4_0)
        filter.setRatingThreshold(.over4_0)

        #expect(filter.ratingThreshold == nil)
    }

    @Test("다른 별점 기준을 설정하면 변경된다")
    func setRatingThresholdChange() {
        var filter = makeFilter()

        filter.setRatingThreshold(.over3_5)
        filter.setRatingThreshold(.over4_8)

        #expect(filter.ratingThreshold == .over4_8)
    }

    @Test("별점 기준을 초기화할 수 있다")
    func clearRatingThreshold() {
        var filter = makeFilter()
        filter.setRatingThreshold(.over4_5)

        filter.clearRatingThreshold()

        #expect(filter.ratingThreshold == nil)
    }

    // MARK: - Keyword

    @Test("키워드를 설정할 수 있다")
    func setKeywords() throws {
        var filter = makeFilter()
        let keywords = [Keyword(id: 1, name: "이세계"), Keyword(id: 2, name: "환생")]

        try filter.setKeywords(keywords)

        #expect(filter.keywords.count == 2)
    }

    @Test("키워드는 최대 20개까지 설정할 수 있다")
    func setKeywordsMax() throws {
        var filter = makeFilter()
        let keywords = (1...20).map { Keyword(id: $0, name: "키워드\($0)") }

        try filter.setKeywords(keywords)

        #expect(filter.keywords.count == 20)
    }

    @Test("키워드가 20개를 초과하면 에러를 던진다")
    func setKeywordsOverLimit() {
        var filter = makeFilter()
        let keywords = (1...21).map { Keyword(id: $0, name: "키워드\($0)") }

        #expect(throws: NovelSearchFilter.ValidationError.keywordOverLimit(max: 20)) {
            try filter.setKeywords(keywords)
        }
    }

    @Test("특정 키워드를 제거할 수 있다")
    func removeKeyword() throws {
        var filter = makeFilter()
        let keyword = Keyword(id: 1, name: "이세계")
        try filter.setKeywords([keyword, Keyword(id: 2, name: "환생")])

        filter.removeKeyword(keyword)

        #expect(filter.keywords.count == 1)
        #expect(filter.keywords.first?.name == "환생")
    }

    @Test("키워드를 전체 초기화할 수 있다")
    func clearKeywords() throws {
        var filter = makeFilter()
        try filter.setKeywords([Keyword(id: 1, name: "이세계")])

        filter.clearKeywords()

        #expect(filter.keywords.isEmpty)
    }

    // MARK: - Clear All

    @Test("전체 필터를 초기화할 수 있다")
    func clearAll() throws {
        var filter = makeFilter(genres: [.fantasy, .romance])
        filter.setPublicationStatus(.completed)
        filter.setRatingThreshold(.over4_0)
        try filter.setKeywords([Keyword(id: 1, name: "이세계")])

        filter.clearAll()

        #expect(filter.genres.isEmpty)
        #expect(filter.publicationStatus == nil)
        #expect(filter.ratingThreshold == nil)
        #expect(filter.keywords.isEmpty)
    }
}

extension NovelSearchFilterTests {
    private func makeFilter(
        genres: [NovelGenre] = [],
        publicationStatus: NovelPublicationStatus? = nil,
        ratingThreshold: NovelRatingThreshold? = nil,
        keywords: [Keyword] = []
    ) -> NovelSearchFilter {
        NovelSearchFilter(
            genres: genres,
            publicationStatus: publicationStatus,
            ratingThreshold: ratingThreshold,
            keywords: keywords
        )
    }
}
