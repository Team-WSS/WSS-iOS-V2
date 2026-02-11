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

    @Test func `장르를 추가할 수 있다.`() {
        var filter = makeFilter()

        filter.addGenre(.fantasy)

        #expect(filter.genres == [.fantasy])
    }

    @Test func `이미 추가된 장르는 중복 추가되지 않는다.`() {
        var filter = makeFilter(genres: [.fantasy])

        filter.addGenre(.fantasy)

        #expect(filter.genres == [.fantasy])
    }

    @Test func `장르를 제거할 수 있다.`() {
        var filter = makeFilter(genres: [.fantasy, .romance])

        filter.removeGenre(.fantasy)

        #expect(filter.genres == [.romance])
    }

    @Test func `장르를 전체 초기화할 수 있다.`() {
        var filter = makeFilter(genres: [.fantasy, .romance, .BL])

        filter.clearGenres()

        #expect(filter.genres.isEmpty)
    }

    // MARK: - Completion Status

    @Test func `완결 상태를 설정할 수 있다.`() {
        var filter = makeFilter()

        filter.setCompletion(.completed)

        #expect(filter.completionStatus == .completed)
    }

    @Test func `같은 완결 상태를 다시 설정하면 해제된다.`() {
        var filter = makeFilter()

        filter.setCompletion(.completed)
        filter.setCompletion(.completed)

        #expect(filter.completionStatus == nil)
    }

    @Test func `다른 완결 상태를 설정하면 변경된다.`() {
        var filter = makeFilter()

        filter.setCompletion(.completed)
        filter.setCompletion(.onGoing)

        #expect(filter.completionStatus == .onGoing)
    }

    @Test func `완결 상태를 초기화할 수 있다.`() {
        var filter = makeFilter()
        filter.setCompletion(.completed)

        filter.clearCompletion()

        #expect(filter.completionStatus == nil)
    }

    // MARK: - Rating Threshold

    @Test func `별점 기준을 설정할 수 있다.`() {
        var filter = makeFilter()

        filter.setRatingThreshold(.over4_0)

        #expect(filter.ratingThreshold == .over4_0)
    }

    @Test func `같은 별점 기준을 다시 설정하면 해제된다.`() {
        var filter = makeFilter()

        filter.setRatingThreshold(.over4_0)
        filter.setRatingThreshold(.over4_0)

        #expect(filter.ratingThreshold == nil)
    }

    @Test func `다른 별점 기준을 설정하면 변경된다.`() {
        var filter = makeFilter()

        filter.setRatingThreshold(.over3_5)
        filter.setRatingThreshold(.over4_8)

        #expect(filter.ratingThreshold == .over4_8)
    }

    @Test func `별점 기준을 초기화할 수 있다.`() {
        var filter = makeFilter()
        filter.setRatingThreshold(.over4_5)

        filter.clearRatingThreshold()

        #expect(filter.ratingThreshold == nil)
    }

    // MARK: - Keyword

    @Test func `키워드를 설정할 수 있다.`() throws {
        var filter = makeFilter()
        let keywords = [Keyword(id: 1, name: "이세계"), Keyword(id: 2, name: "환생")]

        try filter.setKeywords(keywords)

        #expect(filter.keywords.count == 2)
    }

    @Test func `키워드는 최대 20개까지 설정할 수 있다.`() throws {
        var filter = makeFilter()
        let keywords = (1...20).map { Keyword(id: $0, name: "키워드\($0)") }

        try filter.setKeywords(keywords)

        #expect(filter.keywords.count == 20)
    }

    @Test func `키워드가 20개를 초과하면 에러를 던진다.`() {
        var filter = makeFilter()
        let keywords = (1...21).map { Keyword(id: $0, name: "키워드\($0)") }

        #expect(throws: NovelSearchFilter.ValidationError.keywordOverLimit(max: 20)) {
            try filter.setKeywords(keywords)
        }
    }

    @Test func `특정 키워드를 제거할 수 있다.`() throws {
        var filter = makeFilter()
        let keyword = Keyword(id: 1, name: "이세계")
        try filter.setKeywords([keyword, Keyword(id: 2, name: "환생")])

        filter.removeKeyword(keyword)

        #expect(filter.keywords.count == 1)
        #expect(filter.keywords.first?.name == "환생")
    }

    @Test func `키워드를 전체 초기화할 수 있다.`() throws {
        var filter = makeFilter()
        try filter.setKeywords([Keyword(id: 1, name: "이세계")])

        filter.clearKeywords()

        #expect(filter.keywords.isEmpty)
    }

    // MARK: - Clear All

    @Test func `전체 필터를 초기화할 수 있다.`() throws {
        var filter = makeFilter(genres: [.fantasy, .romance])
        filter.setCompletion(.completed)
        filter.setRatingThreshold(.over4_0)
        try filter.setKeywords([Keyword(id: 1, name: "이세계")])

        filter.clearAll()

        #expect(filter.genres.isEmpty)
        #expect(filter.completionStatus == nil)
        #expect(filter.ratingThreshold == nil)
        #expect(filter.keywords.isEmpty)
    }
}

extension NovelSearchFilterTests {
    private func makeFilter(
        genres: [NovelGenre] = [],
        completionStatus: CompletionStatus? = nil,
        ratingThreshold: RatingThreshold? = nil,
        keywords: [Keyword] = []
    ) -> NovelSearchFilter {
        NovelSearchFilter(
            genres: genres,
            completionStatus: completionStatus,
            ratingThreshold: ratingThreshold,
            keywords: keywords
        )
    }
}
