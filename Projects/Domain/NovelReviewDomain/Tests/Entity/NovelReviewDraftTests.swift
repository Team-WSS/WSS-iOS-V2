//
//  NovelReviewDraftTests.swift
//  NovelReviewDomain
//
//  Created by YunhakLee on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

import BaseDomain
import NovelReviewDomain

@Suite("리뷰 초안 작성")
struct NovelReviewDraftTests {

    // 고정 날짜. 둘 다 기준일(today)보다 앞이라 '미래 날짜'에 걸리지 않는다.
    private let firstDay = Date(timeIntervalSince1970: 1_700_000_000)
    private let lastDay = Date(timeIntervalSince1970: 1_700_259_200)  // firstDay + 3일
    private let today = Date(timeIntervalSince1970: 1_701_000_000)

    // MARK: - 기간

    @Test("독서 상태에 맞게 기간을 고쳐서 담는다")
    func normalizesPeriodOnCreation() throws {
        let period = try ReadingPeriod(start: firstDay, end: nil, notAfter: today)

        let draft = makeDraft(status: .watched, period: period)

        #expect(draft.period?.start == firstDay)
        #expect(draft.period?.end == firstDay)
    }

    @Test("독서 상태를 바꾸면 기간도 새 상태에 맞게 고친다")
    func changingStatusNormalizesPeriod() throws {
        let period = try ReadingPeriod(start: firstDay, end: lastDay, notAfter: today)
        var draft = makeDraft(status: .watched, period: period)

        draft.changeStatus(.quit)

        #expect(draft.status == .quit)
        #expect(draft.period?.start == nil)
        #expect(draft.period?.end == lastDay)
    }

    @Test("기간을 넣으면 지금 독서 상태에 맞게 고친다")
    func settingPeriodNormalizesForCurrentStatus() throws {
        var draft = makeDraft(status: .watching)
        let period = try ReadingPeriod(start: firstDay, end: lastDay, notAfter: today)

        draft.setPeriod(period)

        #expect(draft.period?.start == firstDay)
        #expect(draft.period?.end == nil)
    }

    // MARK: - 평점

    @Test("저장된 평점으로 초안을 만들면 그 평점이 담겨 있다")
    func keepsRatingOnCreation() throws {
        let rating = try Rating(4.0)

        let draft = makeDraft(rating: rating)

        #expect(draft.rating == rating)
    }

    @Test("평점을 바꾸면 새 평점이 담긴다")
    func changingRatingReplacesIt() throws {
        // 비어 있지 않은 평점에서 시작한다 — 처음 넣기가 아니라 바꾸기를 본다.
        var draft = makeDraft(rating: try Rating(4.0))
        let newRating = try Rating(2.5)

        draft.setRating(newRating)

        #expect(draft.rating == newRating)
    }

    // MARK: - 매력 포인트

    @Test("매력 포인트를 3개까지 고를 수 있다")
    func selectsUpToThreeAttractivePoints() throws {
        var draft = makeDraft(attractivePoints: [.worldview, .material])

        try draft.addAttractivePoint(.character)

        #expect(draft.attractivePoints.count == 3)
        #expect(draft.attractivePoints == [.worldview, .material, .character])
    }

    @Test("매력 포인트를 3개 고른 뒤에는 더 고를 수 없다")
    func cannotSelectMoreThanThreeAttractivePoints() {
        var draft = makeDraft(attractivePoints: [.worldview, .material, .character])

        #expect(throws: NovelReviewDraft.ValidationError.tooManyAttractivePoints(max: 3)) {
            try draft.addAttractivePoint(.vibe)
        }
    }

    @Test("이미 고른 매력 포인트를 또 고르면 아무 일도 없다")
    func reselectingAttractivePointChangesNothing() throws {
        // 꽉 찬 상태에서 시작한다 — 개수를 따지기 전에 이미 고른 것인지부터 봐야 막히지 않는다.
        var draft = makeDraft(attractivePoints: [.worldview, .material, .character])

        try draft.addAttractivePoint(.worldview)

        #expect(draft.attractivePoints == [.worldview, .material, .character])
    }

    @Test("고른 매력 포인트를 빼면 목록에서 사라진다")
    func removingAttractivePointDropsIt() {
        var draft = makeDraft(attractivePoints: [.worldview, .material])

        draft.removeAttractivePoint(.worldview)

        #expect(draft.attractivePoints == [.material])
    }

    // MARK: - 키워드

    @Test("키워드는 20개까지 담을 수 있다")
    func holdsUpToTwentyKeywords() throws {
        var draft = makeDraft()
        let keywords = makeKeywords(count: 20)

        try draft.setKeywords(keywords)

        // 담는 순서는 지키지 않는다(명세 아님) — 무엇이 담겼는지만 본다.
        #expect(Set(draft.keywords) == Set(keywords))
    }

    @Test("키워드가 20개를 넘으면 담을 수 없다")
    func cannotHoldMoreThanTwentyKeywords() {
        var draft = makeDraft()
        let keywords = makeKeywords(count: 21)

        #expect(throws: NovelReviewDraft.ValidationError.tooManyKeywords(max: 20)) {
            try draft.setKeywords(keywords)
        }
    }

    @Test("같은 키워드가 두 번 들어오면 담을 수 없다")
    func cannotHoldDuplicateKeyword() {
        var draft = makeDraft()
        let keyword = makeKeyword(1)

        #expect(throws: NovelReviewDraft.ValidationError.duplicateKeyword) {
            try draft.setKeywords([keyword, keyword])
        }
    }

    @Test("담긴 키워드를 빼면 목록에서 사라진다")
    func removingKeywordDropsIt() {
        var draft = makeDraft(keywords: [makeKeyword(1), makeKeyword(2)])

        draft.removeKeyword(makeKeyword(1))

        #expect(draft.keywords == [makeKeyword(2)])
    }

    // MARK: - Helpers

    private func makeDraft(
        status: ReadingStatus = .watching,
        period: ReadingPeriod? = nil,
        rating: Rating? = nil,
        attractivePoints: [AttractivePoint] = [],
        keywords: [Keyword] = []
    ) -> NovelReviewDraft {
        NovelReviewDraft(
            novelID: NovelID(1),
            status: status,
            period: period,
            rating: rating,
            attractivePoints: attractivePoints,
            keywords: keywords
        )
    }

    private func makeKeyword(_ id: Int) -> Keyword {
        Keyword(id: KeywordID(id), name: "키워드\(id)")
    }

    private func makeKeywords(count: Int) -> [Keyword] {
        (1...count).map(makeKeyword)
    }
}
