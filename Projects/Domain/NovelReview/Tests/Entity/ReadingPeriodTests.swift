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

@Suite("ReadingPeriod")
struct ReadingPeriodTests {

    @Test("accepts start and end when start < end")
    func acceptsStartBeforeEnd() throws {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let end   = Date(timeIntervalSince1970: 1_700_000_100)

        let period = try ReadingPeriod(start: start, end: end)

        #expect(period.start == start)
        #expect(period.end == end)
    }

    @Test("accepts start equal to end")
    func acceptsStartEqualToEnd() throws {
        let d = Date(timeIntervalSince1970: 1_700_000_000)

        let period = try ReadingPeriod(start: d, end: d)

        #expect(period.start == d)
        #expect(period.end == d)
    }

    @Test("accepts only start date")
    func acceptsOnlyStart() throws {
        let start = Date(timeIntervalSince1970: 1_700_000_000)

        let period = try ReadingPeriod(start: start, end: nil)

        #expect(period.start == start)
        #expect(period.end == nil)
    }

    @Test("accepts only end date")
    func acceptsOnlyEnd() throws {
        let end = Date(timeIntervalSince1970: 1_700_000_000)

        let period = try ReadingPeriod(start: nil, end: end)

        #expect(period.start == nil)
        #expect(period.end == end)
    }

    @Test("rejects when both start and end are nil")
    func rejectsBothNil() {
        #expect(throws: ReadingPeriod.ValidationError.invalidPeriod) {
            _ = try ReadingPeriod(start: nil, end: nil)
        }
    }

    @Test("rejects when start is after end")
    func rejectsStartAfterEnd() {
        let start = Date(timeIntervalSince1970: 1_700_000_100)
        let end   = Date(timeIntervalSince1970: 1_700_000_000)

        #expect(throws: ReadingPeriod.ValidationError.startAfterEnd) {
            _ = try ReadingPeriod(start: start, end: end)
        }
    }

    @Test("equatable compares by start and end")
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
