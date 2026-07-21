//
//  MyLibraryFilterTests.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import NovelDomain
import NovelDomainTesting
import BaseDomain

@Suite
struct MyLibraryFilterTests {

    // MARK: - Interest

    @Test("관심 필터를 토글하면 켜지고, 다시 토글하면 꺼진다")
    func toggleInterest() {
        var filter = makeFilter()

        filter.toggleInterest()
        #expect(filter.isInterest)

        filter.toggleInterest()
        #expect(!filter.isInterest)
    }

    // MARK: - ReadingStatus

    @Test("읽기 상태를 추가할 수 있다")
    func addReadingStatus() {
        var filter = makeFilter()

        filter.addReadingStatus(.watching)

        #expect(filter.readingStatus == [.watching])
    }

    @Test("이미 추가된 읽기 상태는 중복 추가되지 않는다")
    func addReadingStatusDuplicate() {
        var filter = makeFilter(readingStatus: [.watching])

        filter.addReadingStatus(.watching)

        #expect(filter.readingStatus == [.watching])
    }

    @Test("특정 읽기 상태를 제거할 수 있다")
    func removeReadingStatus() {
        var filter = makeFilter(readingStatus: [.watching, .watched])

        filter.removeReadingStatus(.watching)

        #expect(filter.readingStatus == [.watched])
    }

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

    @Test("특정 장르를 제거할 수 있다")
    func removeGenre() {
        var filter = makeFilter(genres: [.fantasy, .romance])

        filter.removeGenre(.fantasy)

        #expect(filter.genres == [.romance])
    }

    // MARK: - PublicationStatus

    @Test("연재 상태를 설정할 수 있다")
    func setPublicationStatus() {
        var filter = makeFilter()

        filter.setPublicationStatus(.onGoing)

        #expect(filter.publicationStatus == .onGoing)
    }

    @Test("연재 상태에 nil을 전달하면 해제된다")
    func clearPublicationStatus() {
        var filter = makeFilter(publicationStatus: .completed)

        filter.setPublicationStatus(nil)

        #expect(filter.publicationStatus == nil)
    }

    // MARK: - Rating (setRatingRange)

    @Test("별점 범위를 설정할 수 있다")
    func setRatingRange() {
        var filter = makeFilter()

        filter.setRatingRange(min: 3.5, max: 4.0)

        #expect(filter.rating == .range(min: 3.5, max: 4.0))
    }

    @Test("별점 범위가 경계를 벗어나면 경계값으로 보정된다")
    func setRatingRangeClampsToBounds() {
        var filter = makeFilter()

        filter.setRatingRange(min: -1.0, max: 4.0)

        #expect(filter.rating == .range(min: 0.0, max: 4.0))
    }

    @Test("min이 max보다 크면 별점 범위 설정이 무시된다")
    func setRatingRangeIgnoresInvertedRange() {
        var filter = makeFilter()
        filter.setRatingRange(min: 3.5, max: 4.0)

        filter.setRatingRange(min: 4.5, max: 4.0)

        #expect(filter.rating == .range(min: 3.5, max: 4.0))
    }

    @Test("전체 범위(0.0~5.0)를 설정하면 별점 필터가 없는 상태로 정규화된다")
    func setRatingRangeFullRangeNormalizesToNil() {
        var filter = makeFilter()
        filter.setRatingRange(min: 3.5, max: 4.0)

        filter.setRatingRange(min: 0.0, max: 5.0)

        #expect(filter.rating == nil)
    }

    // MARK: - Rating (unratedOnly)

    @Test("별점 없음 필터를 설정하면 기존 범위 필터를 대체한다")
    func setUnratedOnlyReplacesRange() {
        var filter = makeFilter()
        filter.setRatingRange(min: 3.5, max: 4.0)

        filter.setUnratedOnly()

        #expect(filter.rating == .unratedOnly)
    }

    @Test("별점 필터를 해제할 수 있다")
    func clearRating() {
        var filter = makeFilter()
        filter.setUnratedOnly()

        filter.clearRating()

        #expect(filter.rating == nil)
    }

    // MARK: - AttractivePoint

    @Test("매력 포인트를 추가할 수 있다")
    func addAttractivePoint() {
        var filter = makeFilter()

        filter.addAttractivePoint(.worldview)

        #expect(filter.attractivePoint == [.worldview])
    }

    @Test("이미 추가된 매력 포인트는 중복 추가되지 않는다")
    func addAttractivePointDuplicate() {
        var filter = makeFilter(attractivePoint: [.worldview])

        filter.addAttractivePoint(.worldview)

        #expect(filter.attractivePoint == [.worldview])
    }

    @Test("특정 매력 포인트를 제거할 수 있다")
    func removeAttractivePoint() {
        var filter = makeFilter(attractivePoint: [.worldview, .character])

        filter.removeAttractivePoint(.worldview)

        #expect(filter.attractivePoint == [.character])
    }

    // MARK: - Keyword

    @Test("키워드를 추가할 수 있다")
    func addKeyword() {
        var filter = makeFilter()
        let keyword = makeKeyword(id: 1, name: "빙의")

        filter.addKeyword(keyword)

        #expect(filter.keywords == [keyword])
    }

    @Test("이미 추가된 키워드는 중복 추가되지 않는다")
    func addKeywordDuplicate() {
        let keyword = makeKeyword(id: 1, name: "빙의")
        var filter = makeFilter(keywords: [keyword])

        filter.addKeyword(keyword)

        #expect(filter.keywords == [keyword])
    }

    @Test("특정 키워드를 제거할 수 있다")
    func removeKeyword() {
        let binge = makeKeyword(id: 1, name: "빙의")
        let regret = makeKeyword(id: 2, name: "후회")
        var filter = makeFilter(keywords: [binge, regret])

        filter.removeKeyword(binge)

        #expect(filter.keywords == [regret])
    }

    // MARK: - SortType

    @Test("정렬 기준을 변경할 수 있다")
    func setSortType() {
        var filter = makeFilter()

        filter.setSortType(.ratingHighest)

        #expect(filter.sortType == .ratingHighest)
    }

    // MARK: - Clear All

    @Test("초기화하면 시트 필터 6종이 모두 리셋된다")
    func clearAllResetsSheetFilters() {
        var filter = makeFilter(
            readingStatus: [.watching],
            genres: [.fantasy],
            publicationStatus: .onGoing,
            attractivePoint: [.worldview],
            keywords: [makeKeyword(id: 1, name: "빙의")]
        )
        filter.setRatingRange(min: 3.5, max: 4.0)

        filter.clearAll()

        #expect(filter.readingStatus.isEmpty)
        #expect(filter.genres.isEmpty)
        #expect(filter.publicationStatus == nil)
        #expect(filter.rating == nil)
        #expect(filter.attractivePoint.isEmpty)
        #expect(filter.keywords.isEmpty)
    }

    @Test("초기화해도 관심 토글과 정렬 기준은 유지된다")
    func clearAllKeepsInterestAndSortType() {
        var filter = makeFilter(readingStatus: [.watching])
        filter.toggleInterest()
        filter.setSortType(.title)

        filter.clearAll()

        #expect(filter.isInterest)
        #expect(filter.sortType == .title)
    }

    // MARK: - hasActiveSheetFilter

    @Test("시트 필터가 하나라도 걸려 있으면 hasActiveSheetFilter가 true다")
    func hasActiveSheetFilterWhenFiltered() {
        var filter = makeFilter()

        filter.addGenre(.fantasy)

        #expect(filter.hasActiveSheetFilter)
    }

    @Test("관심 토글과 정렬만 바뀐 상태는 hasActiveSheetFilter가 false다")
    func hasActiveSheetFilterIgnoresInterestAndSort() {
        var filter = makeFilter()

        filter.toggleInterest()
        filter.setSortType(.readDate)

        #expect(!filter.hasActiveSheetFilter)
    }
}

extension MyLibraryFilterTests {
    private func makeFilter(
        readingStatus: [ReadingStatus] = [],
        genres: [NovelGenre] = [],
        publicationStatus: NovelPublicationStatus? = nil,
        attractivePoint: [AttractivePoint] = [],
        keywords: [Keyword] = []
    ) -> MyLibraryFilter {
        MyLibraryFilter(
            readingStatus: readingStatus,
            genres: genres,
            publicationStatus: publicationStatus,
            attractivePoint: attractivePoint,
            keywords: keywords
        )
    }

    private func makeKeyword(id: Int, name: String) -> Keyword {
        Keyword(id: KeywordID(id), name: name)
    }
}
