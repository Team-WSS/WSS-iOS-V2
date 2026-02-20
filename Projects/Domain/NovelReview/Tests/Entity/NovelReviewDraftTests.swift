//
//  NovelReviewDraftTests 2.swift
//  NovelReviewDomain
//
//  Created by YunhakLee on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Foundation
import Testing
import NovelReviewDomain
import BaseDomain

@Suite("NovelReviewDraft")
struct NovelReviewDraftTests {

    // MARK: - Helpers

    private func makeKeyword(_ id: Int) -> Keyword {
        Keyword(id: KeywordID(id), name: "K\(id)")
    }

    private func makeDraft(
        status: ReadingStatus = .watching,
        period: ReadingPeriod? = nil,
        rating: Rating? = nil,
        attractivePoints: [AttractivePoint] = [],
        keywords: [Keyword] = []
    ) -> NovelReviewDraft {
        NovelReviewDraft(
            novelID: NovelID(42),
            status: status,
            period: period,
            rating: rating,
            attractivePoints: attractivePoints,
            keywords: keywords
        )
    }

    // MARK: - Init rules

    @Test("초기화 시 매력 포인트는 중복이 제거되고 최대 3개까지만 유지된다")
    func initNormalizesAttractivePoints() {
        // duplicates + more than 3
        let input: [AttractivePoint] = [
            .worldview, .worldview, .material, .character, .relationship, .character
        ]

        let draft = makeDraft(attractivePoints: input)

        // max 3
        #expect(draft.attractivePoints.count == 3)
        // unique
        #expect(Set(draft.attractivePoints).count == draft.attractivePoints.count)
    }

    @Test("초기화 시 키워드는 중복이 제거되고 최대 20개까지만 유지된다")
    func initNormalizesKeywords() {
        // 25 items with duplicates
        let base = (1...25).map(makeKeyword)
        let input = base + [makeKeyword(1), makeKeyword(2), makeKeyword(3)] // duplicates

        let draft = makeDraft(keywords: input)

        #expect(draft.keywords.count == 20)
        #expect(Set(draft.keywords).count == draft.keywords.count)
    }

    @Test("초기화 시 읽기 상태에 따라 기간이 정규화된다")
    func initNormalizesPeriodByStatus() throws {
        let d = Date(timeIntervalSince1970: 1_700_000_000)

        // watched인데 end만 들어온 period → normalized가 start/end를 채우는 정책이라고 가정
        // (ReadingPeriod.normalized(for:) 내부 정책에 맞춰 draft가 그 결과를 채택하는지만 검증)
        let p = try ReadingPeriod(start: nil, end: d)

        let draft = makeDraft(status: .watched, period: p)

        let out = try #require(draft.period)
        // "normalized(for: .watched)"의 결과를 기대해야 하므로,
        // 여기서는 최소한 'draft.period가 nil이 아니며, status에 의해 변경될 수 있다' 정도만 확인
        // 정책이 "watched이면 start/end가 둘 다 있어야 한다"라면 아래처럼 강하게 체크 가능:
        #expect(out.start != nil)
        #expect(out.end != nil)
    }

    // MARK: - Status/period editing

    
    @Test("기간이 nil일 때 상태를 변경해도 기간은 그대로 nil을 유지한다")
    func changeStatusKeepsNilPeriodAcrossStatuses() {
        var draft = makeDraft(status: .watching, period: nil)

        draft.changeStatus(.watched)
        #expect(draft.status == .watched)
        #expect(draft.period == nil)

        draft.changeStatus(.quit)
        #expect(draft.status == .quit)
        #expect(draft.period == nil)

        draft.changeStatus(.watching)
        #expect(draft.status == .watching)
        #expect(draft.period == nil)
    }

    @Test("상태를 변경하면 기존 기간은 새로운 상태 기준으로 정규화된다")
    func changeStatusNormalizesPeriodForAllTransitions() throws {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end   = Date(timeIntervalSince1970: 1_700_000_100)

        // From .watched (start+end)
        do {
            var draft = makeDraft(status: .watched, period: try ReadingPeriod(start: start, end: end))

            draft.changeStatus(.watching)
            let p1 = try #require(draft.period)
            #expect(draft.status == .watching)
            #expect(p1.start != nil)
            #expect(p1.end == nil)

            draft = makeDraft(status: .watched, period: try ReadingPeriod(start: start, end: end))
            draft.changeStatus(.quit)
            let p2 = try #require(draft.period)
            #expect(draft.status == .quit)
            #expect(p2.start == nil)
            #expect(p2.end != nil)
        }

        // From .watching (start only)
        do {
            var draft = makeDraft(status: .watching, period: try ReadingPeriod(start: start, end: nil))

            draft.changeStatus(.watched)
            let p1 = try #require(draft.period)
            #expect(draft.status == .watched)
            #expect(p1.start != nil)
            #expect(p1.end != nil) // normalized should fill end

            draft = makeDraft(status: .watching, period: try ReadingPeriod(start: start, end: nil))
            draft.changeStatus(.quit)
            let p2 = try #require(draft.period)
            #expect(draft.status == .quit)
            #expect(p2.start == nil)
            #expect(p2.end != nil) // quit keeps only end
        }

        // From .quit (end only)
        do {
            var draft = makeDraft(status: .quit, period: try ReadingPeriod(start: nil, end: end))

            draft.changeStatus(.watching)
            let p1 = try #require(draft.period)
            #expect(draft.status == .watching)
            #expect(p1.start != nil) // watching keeps only start
            #expect(p1.end == nil)

            draft = makeDraft(status: .quit, period: try ReadingPeriod(start: nil, end: end))
            draft.changeStatus(.watched)
            let p2 = try #require(draft.period)
            #expect(draft.status == .watched)
            #expect(p2.start != nil)
            #expect(p2.end != nil) // normalized should fill start
        }
    }

    @Test("setPeriod는 현재 상태에 맞게 기간을 정규화하여 저장한다")
    func setPeriodNormalizesForEachStatus() throws {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end   = Date(timeIntervalSince1970: 1_700_000_100)

        // status: watching -> should end up with start only
        do {
            var draft = makeDraft(status: .watching, period: nil)
            draft.setPeriod(try ReadingPeriod(start: start, end: end))
            let p = try #require(draft.period)
            #expect(p.start != nil)
            #expect(p.end == nil)
        }

        // status: watched -> should end up with start+end (if one side missing, normalized fills)
        do {
            var draft = makeDraft(status: .watched, period: nil)
            draft.setPeriod(try ReadingPeriod(start: start, end: nil))
            let p = try #require(draft.period)
            #expect(p.start != nil)
            #expect(p.end != nil)
        }

        // status: quit -> should end up with end only
        do {
            var draft = makeDraft(status: .quit, period: nil)
            draft.setPeriod(try ReadingPeriod(start: start, end: end))
            let p = try #require(draft.period)
            #expect(p.start == nil)
            #expect(p.end != nil)
        }

        // set nil clears
        do {
            var draft = makeDraft(status: .watched, period: try ReadingPeriod(start: start, end: end))
            draft.setPeriod(nil)
            #expect(draft.period == nil)
        }
    }

    // MARK: - Rating

    @Test("평점은 설정 및 nil 초기화가 가능하다")
    func setRatingUpdates() throws {
        var draft = makeDraft(rating: nil)
        let r = try Rating(4.5)

        draft.setRating(r)
        #expect(draft.rating == r)

        draft.setRating(nil)
        #expect(draft.rating == nil)
    }

    // MARK: - Attractive points editing rules

    @Test("이미 선택된 매력 포인트를 다시 추가해도 중복되지 않는다")
    func addAttractivePointIgnoresDuplicates() throws {
        var draft = makeDraft(attractivePoints: [.worldview])

        try draft.addAttractivePoint(.worldview) // duplicate
        #expect(draft.attractivePoints == [.worldview])
    }

    @Test("매력 포인트가 3개를 초과하면 예외가 발생한다")
    func addAttractivePointThrowsOnOverflow() throws {
        var draft = makeDraft(attractivePoints: [.worldview, .material, .character])

        #expect(throws: NovelReviewDraft.ValidationError.tooManyAttractivePoints(max: 3)) {
            try draft.addAttractivePoint(.relationship)
        }
    }

    @Test("매력 포인트 삭제는 여러 번 호출해도 안전하다")
    func removeAttractivePointIsIdempotent() {
        var draft = makeDraft(attractivePoints: [.vibe, .material])

        draft.removeAttractivePoint(.vibe)
        #expect(draft.attractivePoints == [.material])

        // removing again should be no-op
        draft.removeAttractivePoint(.vibe)
        #expect(draft.attractivePoints == [.material])
    }

    // MARK: - Keywords editing rules

    @Test("키워드를 20개 초과로 설정하면 예외가 발생한다")
    func setKeywordsThrowsOnOverflow() async throws {
        var draft = makeDraft()
        let twentyOne = (1...21).map(makeKeyword)

        #expect(throws: NovelReviewDraft.ValidationError.tooManyKeywords(max: 20)) {
            try draft.setKeywords(twentyOne)
        }
    }

    @Test("키워드는 20개 이하일 경우 정상적으로 설정된다")
    func setKeywordsAcceptsUnderMax() throws {
        var draft = makeDraft()
        let input = (1...20).map(makeKeyword)

        try draft.setKeywords(input)
        #expect(draft.keywords.count == 20)
    }

    @Test("키워드 삭제는 여러 번 호출해도 안전하다")
    func removeKeywordIsIdempotent() {
        let k1 = makeKeyword(1)
        let k2 = makeKeyword(2)

        var draft = makeDraft(keywords: [k1, k2])

        draft.removeKeyword(k1)
        #expect(draft.keywords == [k2])

        // removing again should be no-op
        draft.removeKeyword(k1)
        #expect(draft.keywords == [k2])
    }
}
