//
//  MyLibraryFilterTests.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import NovelDomain
@testable import BaseDomain

@Suite
struct MyLibraryFilterTests {

    // MARK: - ReadStatus

    @Test("읽기 상태를 추가할 수 있다")
    func addReadStatus() {
        var filter = makeFilter()

        filter.addReadStatus(.watching)

        #expect(filter.readStatus == [.watching])
    }

    @Test("이미 추가된 읽기 상태는 중복 추가되지 않는다")
    func addReadStatusDuplicate() {
        var filter = makeFilter(readStatus: [.watching])

        filter.addReadStatus(.watching)

        #expect(filter.readStatus == [.watching])
    }

    @Test("특정 읽기 상태를 제거할 수 있다")
    func removeReadStatus() {
        var filter = makeFilter(readStatus: [.watching, .watched])

        filter.removeGenre(.watching)

        #expect(filter.readStatus == [.watched])
    }

    @Test("읽기 상태를 전체 초기화할 수 있다")
    func clearReadStatuses() {
        var filter = makeFilter(readStatus: [.watching, .watched, .quit])

        filter.clearReadStatuses()

        #expect(filter.readStatus.isEmpty)
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

        filter.removeGenre(.worldview)

        #expect(filter.attractivePoint == [.character])
    }

    @Test("매력 포인트를 전체 초기화할 수 있다")
    func clearAttractivePoints() {
        var filter = makeFilter(attractivePoint: [.worldview, .character, .vibe])

        filter.clearAttractivePoints()

        #expect(filter.attractivePoint.isEmpty)
    }

    // MARK: - RatingThreshold

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

    // MARK: - Clear All

    @Test("전체 필터를 초기화할 수 있다")
    func clearAll() {
        var filter = makeFilter(
            readStatus: [.watching, .watched],
            attractivePoint: [.worldview]
        )
        filter.setRatingThreshold(.over4_0)

        filter.clearAll()

        #expect(filter.readStatus.isEmpty)
        #expect(filter.attractivePoint.isEmpty)
        #expect(filter.ratingThreshold == nil)
    }
}

extension MyLibraryFilterTests {
    private func makeFilter(
        readStatus: [ReadingStatus] = [],
        attractivePoint: [AttractivePoint] = [],
        ratingThreshold: NovelRatingThreshold? = nil
    ) -> MyLibraryFilter {
        MyLibraryFilter(
            readStatus: readStatus,
            attractivePoint: attractivePoint,
            ratingThreshold: ratingThreshold
        )
    }
}
