//
//  SearchFilterTests.swift
//  SearchDomain
//
//  Created by Seoyeon Choi on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import SearchDomain
import BaseDomain

@Suite
struct SearchFilterTests {

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

    // MARK: - Platform

    @Test("플랫폼을 추가할 수 있다")
    func addPlatform() {
        var filter = makeFilter()

        filter.addPlatform(.kakaoPage)

        #expect(filter.platforms == [.kakaoPage])
    }

    @Test("이미 추가된 플랫폼은 중복 추가되지 않는다")
    func addPlatformDuplicate() {
        var filter = makeFilter(platforms: [.kakaoPage])

        filter.addPlatform(.kakaoPage)

        #expect(filter.platforms == [.kakaoPage])
    }

    @Test("플랫폼을 제거할 수 있다")
    func removePlatform() {
        var filter = makeFilter(platforms: [.kakaoPage, .ridibooks])

        filter.removePlatform(.kakaoPage)

        #expect(filter.platforms == [.ridibooks])
    }

    // MARK: - Publication Status

    @Test("출판 상태를 설정할 수 있다")
    func setPublicationStatus() {
        var filter = makeFilter()

        filter.setPublicationStatus(.completed)

        #expect(filter.publicationStatus == .completed)
    }

    @Test("nil을 전달하면 출판 상태가 해제된다")
    func setPublicationStatusToggle() {
        var filter = makeFilter()

        filter.setPublicationStatus(.completed)
        filter.setPublicationStatus(nil)

        #expect(filter.publicationStatus == nil)
    }

    @Test("다른 출판 상태를 설정하면 변경된다")
    func setPublicationStatusChange() {
        var filter = makeFilter()

        filter.setPublicationStatus(.completed)
        filter.setPublicationStatus(.onGoing)

        #expect(filter.publicationStatus == .onGoing)
    }

    // MARK: - Rating Threshold

    @Test("별점 기준을 설정할 수 있다")
    func setRatingThreshold() {
        var filter = makeFilter()

        filter.setRatingThreshold(.over4_0)

        #expect(filter.ratingThreshold == .over4_0)
    }

    @Test("nil을 전달하면 별점 기준이 해제된다")
    func setRatingThresholdToggle() {
        var filter = makeFilter()

        filter.setRatingThreshold(.over4_0)
        filter.setRatingThreshold(nil)

        #expect(filter.ratingThreshold == nil)
    }

    @Test("다른 별점 기준을 설정하면 변경된다")
    func setRatingThresholdChange() {
        var filter = makeFilter()

        filter.setRatingThreshold(.over3_5)
        filter.setRatingThreshold(.over4_8)

        #expect(filter.ratingThreshold == .over4_8)
    }

    // MARK: - Rating Range

    @Test("별점 범위를 설정할 수 있다")
    func setRatingRange() {
        var filter = makeFilter()

        filter.setRatingRange(min: 3.5, max: 4.0)

        #expect(filter.ratingRange == NovelRatingRange(min: 3.5, max: 4.0))
    }

    @Test("별점 범위가 경계를 벗어나면 경계값으로 보정된다")
    func setRatingRangeClampsToBounds() {
        var filter = makeFilter()

        filter.setRatingRange(min: -1.0, max: 4.0)

        #expect(filter.ratingRange == NovelRatingRange(min: 0.0, max: 4.0))
    }

    @Test("min이 max보다 크면 별점 범위 설정이 무시된다")
    func setRatingRangeIgnoresInvertedRange() {
        var filter = makeFilter()
        filter.setRatingRange(min: 3.5, max: 4.0)

        filter.setRatingRange(min: 4.5, max: 4.0)

        #expect(filter.ratingRange == NovelRatingRange(min: 3.5, max: 4.0))
    }

    @Test("전체 범위(0.0~5.0)를 설정하면 별점 범위 필터가 없는 상태로 정규화된다")
    func setRatingRangeFullRangeNormalizesToNil() {
        var filter = makeFilter()
        filter.setRatingRange(min: 3.5, max: 4.0)

        filter.setRatingRange(min: 0.0, max: 5.0)

        #expect(filter.ratingRange == nil)
    }

    // MARK: - Keyword

    @Test("키워드를 추가할 수 있다")
    func addKeyword() throws {
        var filter = makeFilter()
        let keyword = Keyword(id: KeywordID(1), name: "이세계")

        try filter.addKeyword(keyword)

        #expect(filter.keywords.count == 1)
        #expect(filter.keywords.first == keyword)
    }

    @Test("키워드는 최대 20개까지 추가할 수 있다")
    func addKeywordMax() throws {
        var filter = makeFilter()

        for i in 1...20 {
            try filter.addKeyword(Keyword(id: KeywordID(i), name: "키워드\(i)"))
        }

        #expect(filter.keywords.count == 20)
    }

    @Test("키워드가 20개를 초과하면 에러를 던진다")
    func addKeywordOverLimit() throws {
        var filter = makeFilter()

        for i in 1...20 {
            try filter.addKeyword(Keyword(id: KeywordID(i), name: "키워드\(i)"))
        }

        #expect(throws: SearchFilter.ValidationError.keywordOverLimit(max: 20)) {
            try filter.addKeyword(Keyword(id: KeywordID(21), name: "키워드21"))
        }
    }

    @Test("특정 키워드를 제거할 수 있다")
    func removeKeyword() throws {
        var filter = makeFilter()
        let keyword = Keyword(id: KeywordID(1), name: "이세계")
        try filter.addKeyword(keyword)
        try filter.addKeyword(Keyword(id: KeywordID(2), name: "현대"))
        
        filter.removeKeyword(keyword)

        #expect(filter.keywords.count == 1)
        #expect(filter.keywords.first?.name == "현대")
    }

    @Test("키워드 선택 결과를 일괄 반영할 수 있다")
    func setKeywords() throws {
        var filter = makeFilter()
        try filter.addKeyword(Keyword(id: KeywordID(99), name: "이전선택"))
        let newKeywords = [Keyword(id: KeywordID(1), name: "이세계"), Keyword(id: KeywordID(2), name: "현대")]

        filter.setKeywords(newKeywords)

        #expect(filter.keywords == newKeywords)
    }

    @Test("일괄 반영 시 최대 개수를 초과하면 나머지는 잘려나간다")
    func setKeywordsClampsToMax() {
        var filter = makeFilter()
        let overLimitKeywords = (1...25).map { Keyword(id: KeywordID($0), name: "키워드\($0)") }

        filter.setKeywords(overLimitKeywords)

        #expect(filter.keywords.count == 20)
        #expect(filter.keywords == Array(overLimitKeywords.prefix(20)))
    }

    @Test("키워드만 초기화할 수 있다")
    func clearKeywords() throws {
        var filter = makeFilter()
        try filter.addKeyword(Keyword(id: KeywordID(1), name: "이세계"))

        filter.clearKeywords()

        #expect(filter.keywords.isEmpty)
    }

    // MARK: - Clear (탭별)

    @Test("정보 탭 필터(장르·플랫폼·연재상태·별점범위)만 초기화하고 키워드·별점기준은 남는다")
    func clearInfoFilters() throws {
        var filter = makeFilter(genres: [.fantasy, .romance], platforms: [.kakaoPage])
        filter.setPublicationStatus(.completed)
        filter.setRatingThreshold(.over4_0)
        filter.setRatingRange(min: 3.5, max: 4.0)
        try filter.addKeyword(Keyword(id: KeywordID(1), name: "이세계"))

        filter.clearInfoFilters()

        #expect(filter.genres.isEmpty)
        #expect(filter.platforms.isEmpty)
        #expect(filter.publicationStatus == nil)
        #expect(filter.ratingRange == nil)
        #expect(filter.ratingThreshold == .over4_0)
        #expect(filter.keywords.count == 1)
    }

    // MARK: - Clear All

    @Test("전체 필터를 초기화할 수 있다")
    func clearAll() throws {
        var filter = makeFilter(genres: [.fantasy, .romance], platforms: [.kakaoPage])
        filter.setPublicationStatus(.completed)
        filter.setRatingThreshold(.over4_0)
        filter.setRatingRange(min: 3.5, max: 4.0)
        try filter.addKeyword(Keyword(id: KeywordID(1), name: "이세계"))

        filter.clearAll()

        #expect(filter.genres.isEmpty)
        #expect(filter.platforms.isEmpty)
        #expect(filter.publicationStatus == nil)
        #expect(filter.ratingThreshold == nil)
        #expect(filter.ratingRange == nil)
        #expect(filter.keywords.isEmpty)
    }
}

extension SearchFilterTests {
    private func makeFilter(
        genres: [NovelGenre] = [],
        platforms: [NovelPlatform] = [],
        publicationStatus: NovelPublicationStatus? = nil,
        ratingThreshold: NovelRatingThreshold? = nil,
        keywords: [Keyword] = []
    ) -> SearchFilter {
        SearchFilter(
            genres: genres,
            platforms: platforms,
            publicationStatus: publicationStatus,
            ratingThreshold: ratingThreshold,
            keywords: keywords
        )
    }
}
