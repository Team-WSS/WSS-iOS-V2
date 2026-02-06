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

@Suite("NovelReviewDraft")
struct NovelReviewDraftTests {

    // MARK: - Helpers

    private func makeKeyword(_ id: Int) -> Keyword {
        Keyword(id: id, name: "K\(id)")
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

    @Test("init removes duplicates and clips attractivePoints to max(3)")
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

    @Test("init removes duplicates and clips keywords to max(20)")
    func initNormalizesKeywords() {
        // 25 items with duplicates
        let base = (1...25).map(makeKeyword)
        let input = base + [makeKeyword(1), makeKeyword(2), makeKeyword(3)] // duplicates

        let draft = makeDraft(keywords: input)

        #expect(draft.keywords.count == 20)
        #expect(Set(draft.keywords).count == draft.keywords.count)
    }

    @Test("init normalizes period based on initial status")
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

    @Test("changeStatus keeps period nil across all statuses")
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

    @Test("changeStatus normalizes period for all status transitions")
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

    @Test("setPeriod normalizes input for each current status")
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

    @Test("setRating updates rating (including nil)")
    func setRatingUpdates() throws {
        var draft = makeDraft(rating: nil)
        let r = try Rating(4.5)

        draft.setRating(r)
        #expect(draft.rating == r)

        draft.setRating(nil)
        #expect(draft.rating == nil)
    }

    // MARK: - Attractive points editing rules

    @Test("addAttractivePoint is idempotent for duplicates")
    func addAttractivePointIgnoresDuplicates() throws {
        var draft = makeDraft(attractivePoints: [.worldview])

        try draft.addAttractivePoint(.worldview) // duplicate
        #expect(draft.attractivePoints == [.worldview])
    }

    @Test("addAttractivePoint throws when exceeding max(3)")
    func addAttractivePointThrowsOnOverflow() throws {
        var draft = makeDraft(attractivePoints: [.worldview, .material, .character])

        #expect(throws: NovelReviewDraft.ValidationError.tooManyAttractivePoints(max: 3)) {
            try draft.addAttractivePoint(.relationship)
        }
    }

    @Test("removeAttractivePoint is idempotent")
    func removeAttractivePointIsIdempotent() {
        var draft = makeDraft(attractivePoints: [.vibe, .material])

        draft.removeAttractivePoint(.vibe)
        #expect(draft.attractivePoints == [.material])

        // removing again should be no-op
        draft.removeAttractivePoint(.vibe)
        #expect(draft.attractivePoints == [.material])
    }

    // MARK: - Keywords editing rules

    @Test("setKeywords throws when exceeding max(20)")
    func setKeywordsThrowsOnOverflow() async throws {
        var draft = makeDraft()
        let twentyOne = (1...21).map(makeKeyword)

        #expect(throws: NovelReviewDraft.ValidationError.tooManyKeywords(max: 20)) {
            try draft.setKeywords(twentyOne)
        }
    }

    @Test("setKeywords accepts <= 20 (current implementation does not dedupe)")
    func setKeywordsAcceptsUnderMax() throws {
        var draft = makeDraft()
        let input = (1...20).map(makeKeyword)

        try draft.setKeywords(input)
        #expect(draft.keywords.count == 20)
    }

    @Test("removeKeyword is idempotent")
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
