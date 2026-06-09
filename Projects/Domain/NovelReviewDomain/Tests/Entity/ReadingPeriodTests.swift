//
//  ReadingPeriodTests.swift
//  NovelReviewDomain
//
//  Created by YunhakLee on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

@testable import NovelReviewDomain
import NovelReviewDomainTesting
import BaseDomain

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

    @Test("종료일이 기준일(오늘) 이후면 기간 생성에 실패한다")
    func rejectsFutureEnd() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        #expect(throws: ReadingPeriod.ValidationError.futureDate) {
            _ = try ReadingPeriod(start: nil, end: tomorrow, notAfter: today)
        }
    }

    @Test("시작일이 기준일(오늘) 이후면 기간 생성에 실패한다")
    func rejectsFutureStart() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        #expect(throws: ReadingPeriod.ValidationError.futureDate) {
            _ = try ReadingPeriod(start: tomorrow, end: tomorrow, notAfter: today)
        }
    }

    @Test("기준일과 같은 날이면(시각이 달라도) 기간 생성이 가능하다")
    func acceptsSameDayAsLimit() throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        let laterSameDay = today.addingTimeInterval(60 * 60)  // 같은 날, 1시간 뒤

        let period = try ReadingPeriod(start: nil, end: laterSameDay, notAfter: today)

        #expect(period.end == laterSameDay)
    }

    @Test("기준일 이전 날짜는 기간 생성이 가능하다")
    func acceptsPastDate() throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let period = try ReadingPeriod(start: yesterday, end: yesterday, notAfter: today)

        #expect(period.start == yesterday)
        #expect(period.end == yesterday)
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
