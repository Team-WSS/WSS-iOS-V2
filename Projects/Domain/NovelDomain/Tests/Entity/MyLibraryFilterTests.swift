//
//  MyLibraryFilterTests.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

import BaseDomain
import NovelDomain

private let regression = Keyword(id: KeywordID(11), name: "회귀")
private let possession = Keyword(id: KeywordID(12), name: "빙의")

@Suite("내 서재 필터")
struct MyLibraryFilterTests {

    @Suite("관심")
    struct Interest {

        @Test("내 서재의 관심 필터는 처음에 꺼져 있다")
        func startsWithInterestOff() {
            let filter = MyLibraryFilter()

            #expect(!filter.isInterest)
        }

        @Test(
            "관심은 누를 때마다 켜지고 꺼진다",
            arguments: [
                (false, true),  // 꺼져 있으면 켜진다
                (true, false)   // 켜져 있으면 꺼진다
            ]
        )
        func togglesOnEachTap(isInterest: Bool, expected: Bool) {
            var filter = MyLibraryFilter(isInterest: isInterest)

            filter.toggleInterest()

            #expect(filter.isInterest == expected)
        }
    }

    @Suite("독서 상태")
    struct ReadingStatusSelection {

        @Test("독서 상태를 고르면 담긴다")
        func addsStatus() {
            var filter = MyLibraryFilter()

            filter.addReadingStatus(.watching)

            #expect(filter.readingStatus == [.watching])
        }

        @Test("이미 고른 독서 상태를 또 고르면 그대로다")
        func ignoresDuplicateStatus() {
            var filter = MyLibraryFilter(readingStatus: [.watching])

            filter.addReadingStatus(.watching)

            #expect(filter.readingStatus == [.watching])
        }

        @Test("고른 독서 상태를 빼면 사라진다")
        func removesStatus() {
            var filter = MyLibraryFilter(readingStatus: [.watching, .watched])

            filter.removeReadingStatus(.watching)

            #expect(filter.readingStatus == [.watched])
        }
    }

    @Suite("장르")
    struct GenreSelection {

        @Test("장르를 고르면 담긴다")
        func addsGenre() {
            var filter = MyLibraryFilter()

            filter.addGenre(.fantasy)

            #expect(filter.genres == [.fantasy])
        }

        @Test("이미 고른 장르를 또 고르면 그대로다")
        func ignoresDuplicateGenre() {
            var filter = MyLibraryFilter(genres: [.fantasy])

            filter.addGenre(.fantasy)

            #expect(filter.genres == [.fantasy])
        }

        @Test("고른 장르를 빼면 사라진다")
        func removesGenre() {
            var filter = MyLibraryFilter(genres: [.fantasy, .romance])

            filter.removeGenre(.fantasy)

            #expect(filter.genres == [.romance])
        }
    }

    @Suite("매력 포인트")
    struct AttractivePointSelection {

        @Test("매력 포인트를 고르면 담긴다")
        func addsAttractivePoint() {
            var filter = MyLibraryFilter()

            filter.addAttractivePoint(.worldview)

            #expect(filter.attractivePoint == [.worldview])
        }

        @Test("이미 고른 매력 포인트를 또 고르면 그대로다")
        func ignoresDuplicateAttractivePoint() {
            var filter = MyLibraryFilter(attractivePoint: [.worldview])

            filter.addAttractivePoint(.worldview)

            #expect(filter.attractivePoint == [.worldview])
        }

        @Test("고른 매력 포인트를 빼면 사라진다")
        func removesAttractivePoint() {
            var filter = MyLibraryFilter(attractivePoint: [.worldview, .character])

            filter.removeAttractivePoint(.worldview)

            #expect(filter.attractivePoint == [.character])
        }
    }

    @Suite("키워드")
    struct KeywordSelection {

        @Test("키워드를 고르면 담긴다")
        func addsKeyword() {
            var filter = MyLibraryFilter()

            filter.addKeyword(regression)

            #expect(filter.keywords == [regression])
        }

        @Test("이미 고른 키워드를 또 고르면 그대로다")
        func ignoresDuplicateKeyword() {
            var filter = MyLibraryFilter(keywords: [regression])

            filter.addKeyword(regression)

            #expect(filter.keywords == [regression])
        }

        @Test("고른 키워드를 빼면 사라진다")
        func removesKeyword() {
            var filter = MyLibraryFilter(keywords: [regression, possession])

            filter.removeKeyword(regression)

            #expect(filter.keywords == [possession])
        }
    }

    @Suite("연재 상태")
    struct PublicationStatusSelection {

        @Test("연재 상태는 하나만 고를 수 있어 새로 고르면 바뀐다")
        func replacesStatus() {
            var filter = MyLibraryFilter(publicationStatus: .onGoing)

            filter.setPublicationStatus(.completed)

            #expect(filter.publicationStatus == .completed)
        }

        @Test("연재 상태 선택을 해제하면 아무것도 선택되지 않은 상태가 된다")
        func clearsStatus() {
            var filter = MyLibraryFilter(publicationStatus: .onGoing)

            filter.setPublicationStatus(nil)

            #expect(filter.publicationStatus == nil)
        }
    }

    @Suite("별점")
    struct Rating {

        @Test(
            "고른 별점 범위가 담긴다",
            arguments: [
                (1.0, 3.0),  // 보통 범위
                (2.0, 2.0)   // 최소와 최대가 같아도 범위다
            ] as [(Float, Float)]
        )
        func keepsRange(min: Float, max: Float) {
            var filter = MyLibraryFilter()

            filter.setRatingRange(min: min, max: max)

            #expect(filter.rating == .range(min: min, max: max))
        }

        @Test(
            "별점 범위가 0점에서 5점 밖이면 안으로 맞춘다",
            arguments: [
                (-1, 3, 0, 3),  // 최소가 0점 아래
                (1, 6, 1, 5)    // 최대가 5점 위
            ] as [(Float, Float, Float, Float)]
        )
        func clampsIntoBounds(min: Float, max: Float, expectedMin: Float, expectedMax: Float) {
            var filter = MyLibraryFilter()

            filter.setRatingRange(min: min, max: max)

            #expect(filter.rating == .range(min: expectedMin, max: expectedMax))
        }

        @Test("최소가 최대보다 크면 받지 않고 이전 별점 범위를 지킨다")
        func rejectsInvertedRange() {
            var filter = MyLibraryFilter(rating: .range(min: 1.0, max: 3.0))

            filter.setRatingRange(min: 4.0, max: 2.0)

            #expect(filter.rating == .range(min: 1.0, max: 3.0))
        }

        @Test(
            "0점에서 5점 전체를 고르면 별점 필터가 없다",
            arguments: [
                (0, 5),   // 딱 전체 범위
                (-1, 6)   // 안으로 맞추면 전체 범위가 된다
            ] as [(Float, Float)]
        )
        func fullRangeMeansNoFilter(min: Float, max: Float) {
            var filter = MyLibraryFilter(rating: .range(min: 1.0, max: 3.0))

            filter.setRatingRange(min: min, max: max)

            #expect(filter.rating == nil)
        }

        @Test("별점 없는 작품만 보기를 고르면 별점 범위 대신 걸린다")
        func unratedOnlyReplacesRange() {
            var filter = MyLibraryFilter(rating: .range(min: 1.0, max: 3.0))

            filter.setUnratedOnly()

            #expect(filter.rating == .unratedOnly)
        }

        @Test("별점 필터를 해제하면 아무 별점 범위도 선택되지 않은 상태가 된다")
        func clearsRating() {
            var filter = MyLibraryFilter(rating: .range(min: 1.0, max: 3.0))

            filter.clearRating()

            #expect(filter.rating == nil)
        }
    }

    @Suite("정렬")
    struct Sort {

        @Test("내 서재의 초기 정렬 타입은 등록 최신순이다")
        func startsWithRegisteredNewest() {
            let filter = MyLibraryFilter()

            #expect(filter.sortType == .registeredNewest)
        }

        @Test("내 서재의 정렬 타입을 변경할 수 있다")
        func keepsChangedSortType() {
            var filter = MyLibraryFilter()

            filter.setSortType(.title)

            #expect(filter.sortType == .title)
        }
    }

    @Suite("초기화")
    struct ClearAll {

        @Test("초기화하면 시트 필터(독서 상태·장르·연재 상태·별점·매력 포인트·키워드)를 모두 비운다")
        func clearsSheetFilters() {
            var filter = makeFilterWithEverything()

            filter.clearAll()

            #expect(filter.readingStatus.isEmpty)
            #expect(filter.genres.isEmpty)
            #expect(filter.publicationStatus == nil)
            #expect(filter.rating == nil)
            #expect(filter.attractivePoint.isEmpty)
            #expect(filter.keywords.isEmpty)
        }

        @Test("초기화해도 관심과 정렬은 그대로 둔다")
        func keepsInterestAndSort() {
            var filter = makeFilterWithEverything()

            filter.clearAll()

            #expect(filter.isInterest)
            #expect(filter.sortType == .title)
        }
    }

    @Suite("필터 표시")
    struct ActiveSheetFilter {

        @Test(
            "시트 필터 중 하나라도 걸리면 필터가 걸린 상태다",
            arguments: [
                MyLibraryFilter(readingStatus: [.watching]),           // 독서 상태
                MyLibraryFilter(genres: [.fantasy]),                   // 장르
                MyLibraryFilter(publicationStatus: .completed),        // 연재 상태
                MyLibraryFilter(rating: .unratedOnly),                 // 별점
                MyLibraryFilter(attractivePoint: [.worldview]),        // 매력 포인트
                MyLibraryFilter(keywords: [regression])                // 키워드
            ]
        )
        func activeWithAnySheetFilter(filter: MyLibraryFilter) {
            let isActive = filter.hasActiveSheetFilter

            #expect(isActive)
        }

        @Test("관심이나 정렬만 바꿨으면 필터가 걸린 상태가 아니다")
        func inactiveWithOnlyInterestAndSort() {
            let filter = MyLibraryFilter(isInterest: true, sortType: .title)

            let isActive = filter.hasActiveSheetFilter

            #expect(!isActive)
        }
    }
}

/// 시트 필터 전부와 관심·정렬을 모두 건 필터.
private func makeFilterWithEverything() -> MyLibraryFilter {
    MyLibraryFilter(
        isInterest: true,
        readingStatus: [.watching],
        genres: [.fantasy],
        publicationStatus: .completed,
        rating: .range(min: 1.0, max: 3.0),
        attractivePoint: [.worldview],
        keywords: [regression],
        sortType: .title
    )
}
