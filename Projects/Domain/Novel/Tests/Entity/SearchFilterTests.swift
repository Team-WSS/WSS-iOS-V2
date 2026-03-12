//
//  SearchFilterTests.swift
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

    // MARK: - Keyword

    @Test("키워드를 추가할 수 있다")
    func addKeyword() throws {
        var filter = makeFilter()
        let keyword = Keyword(id: 1, name: "이세계")

        try filter.addKeyword(keyword)

        #expect(filter.keywords.count == 1)
        #expect(filter.keywords.first == keyword)
    }

    @Test("키워드는 최대 20개까지 추가할 수 있다")
    func addKeywordMax() throws {
        var filter = makeFilter()

        for i in 1...20 {
            try filter.addKeyword(Keyword(id: i, name: "키워드\(i)"))
        }

        #expect(filter.keywords.count == 20)
    }

    @Test("키워드가 20개를 초과하면 에러를 던진다")
    func addKeywordOverLimit() throws {
        var filter = makeFilter()

        for i in 1...20 {
            try filter.addKeyword(Keyword(id: i, name: "키워드\(i)"))
        }

        #expect(throws: SearchFilter.ValidationError.keywordOverLimit(max: 20)) {
            try filter.addKeyword(Keyword(id: 21, name: "키워드21"))
        }
    }

    @Test("특정 키워드를 제거할 수 있다")
    func removeKeyword() throws {
        var filter = makeFilter()
        let keyword = Keyword(id: 1, name: "이세계")
        try filter.addKeyword(keyword)
        try filter.addKeyword(Keyword(id: 2, name: "현대"))
        
        filter.removeKeyword(keyword)

        #expect(filter.keywords.count == 1)
        #expect(filter.keywords.first?.name == "현대")
    }
    
    // MARK: - Clear All

    @Test("전체 필터를 초기화할 수 있다")
    func clearAll() throws {
        var filter = makeFilter(genres: [.fantasy, .romance])
        filter.setPublicationStatus(.completed)
        filter.setRatingThreshold(.over4_0)
        try filter.addKeyword(Keyword(id: 1, name: "이세계"))

        filter.clearAll()

        #expect(filter.genres.isEmpty)
        #expect(filter.publicationStatus == nil)
        #expect(filter.ratingThreshold == nil)
        #expect(filter.keywords.isEmpty)
    }
}

extension SearchFilterTests {
    private func makeFilter(
        genres: [NovelGenre] = [],
        publicationStatus: NovelPublicationStatus? = nil,
        ratingThreshold: NovelRatingThreshold? = nil,
        keywords: [Keyword] = []
    ) -> SearchFilter {
        SearchFilter(
            genres: genres,
            publicationStatus: publicationStatus,
            ratingThreshold: ratingThreshold,
            keywords: keywords
        )
    }
}
