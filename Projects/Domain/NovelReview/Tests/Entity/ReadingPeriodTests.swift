//
//  ReadingPeriodTests.swift
//  NovelReviewDomain
//
//  Created by YunhakLee on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing
import NovelReviewDomain
import NovelReviewDomainTesting

@Suite("ReadingPeriod")
struct ReadingPeriodTests {

    @Test("시작일이 종료일보다 이전이면 기간 생성이 가능하다")
    func acceptsStartBeforeEnd() throws {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end   = Date(timeIntervalSince1970: 1_700_000_100)

        let period = try ReadingPeriod(start: start, end: end)

        #expect(period.start == start)
        #expect(period.end == end)
    }

    @Test("시작일과 종료일이 같아도 기간 생성이 가능하다")
    func acceptsStartEqualToEnd() throws {
        let d = Date(timeIntervalSince1970: 1_700_000_000)

        let period = try ReadingPeriod(start: d, end: d)

        #expect(period.start == d)
        #expect(period.end == d)
    }

    @Test("시작일만 있어도 기간 생성이 가능하다")
    func acceptsOnlyStart() throws {
        let start = Date(timeIntervalSince1970: 1_700_000_000)

        let period = try ReadingPeriod(start: start, end: nil)

        #expect(period.start == start)
        #expect(period.end == nil)
    }

    @Test("종료일만 있어도 기간 생성이 가능하다")
    func acceptsOnlyEnd() throws {
        let end = Date(timeIntervalSince1970: 1_700_000_000)

        let period = try ReadingPeriod(start: nil, end: end)

        #expect(period.start == nil)
        #expect(period.end == end)
    }

    @Test("시작일과 종료일이 모두 없으면 기간 생성에 실패한다")
    func rejectsBothNil() {
        #expect(throws: ReadingPeriod.ValidationError.invalidPeriod) {
            _ = try ReadingPeriod(start: nil, end: nil)
        }
    }

    @Test("시작일이 종료일보다 늦으면 기간 생성에 실패한다")
    func rejectsStartAfterEnd() {
        let start = Date(timeIntervalSince1970: 1_700_000_100)
        let end   = Date(timeIntervalSince1970: 1_700_000_000)

        #expect(throws: ReadingPeriod.ValidationError.startAfterEnd) {
            _ = try ReadingPeriod(start: start, end: end)
        }
    }

    @Test("같은 시작일과 종료일을 가지면 동일한 기간으로 비교된다")
    func equatableByDates() throws {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end   = Date(timeIntervalSince1970: 1_700_000_100)

        let a = try ReadingPeriod(start: start, end: end)
        let b = try ReadingPeriod(start: start, end: end)
        let c = try ReadingPeriod(start: start, end: nil)

        #expect(a == b)
        #expect(a != c)
    }
}
