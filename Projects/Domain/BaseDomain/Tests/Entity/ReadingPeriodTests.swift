//
//  ReadingPeriodTests.swift
//  BaseDomain
//
//  Created by YunhakLee on 2/6/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

import BaseDomain

@Suite("독서 기간")
struct ReadingPeriodTests {

    // 고정 날짜. 기준일(today)은 서울 시각 2023-11-15 07:13이다.
    private static let threeDaysAgo = Date(timeIntervalSince1970: 1_699_740_800)
    private static let yesterday = Date(timeIntervalSince1970: 1_699_913_600)
    private static let today = Date(timeIntervalSince1970: 1_700_000_000)
    private static let tomorrow = Date(timeIntervalSince1970: 1_700_086_400)

    // 날짜는 서울 달력으로 가른다 — 기기 시간대에 따라 결과가 달라지지 않게 고정한다.
    private static let seoul: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        return calendar
    }()

    // MARK: - 만들기

    @Test(
        "시작일이나 종료일 하나만 있어도 기간이 된다",
        arguments: [
            (yesterday, nil),  // 시작일만 있다
            (nil, yesterday)   // 종료일만 있다
        ] as [(Date?, Date?)]
    )
    func oneDateIsEnough(start: Date?, end: Date?) throws {
        let period = try makePeriod(start: start, end: end)

        #expect(period.start == start)
        #expect(period.end == end)
    }

    @Test("같은 날이어도 기간이 된다")
    func sameDayIsPeriod() throws {
        let period = try makePeriod(start: Self.yesterday, end: Self.yesterday)

        #expect(period.start == Self.yesterday)
        #expect(period.end == Self.yesterday)
    }

    @Test("둘 다 없으면 기간이 아니다")
    func noDatesIsNotPeriod() {
        #expect(throws: ReadingPeriod.ValidationError.invalidPeriod) {
            try makePeriod(start: nil, end: nil)
        }
    }

    @Test("시작일이 종료일보다 늦으면 기간이 아니다")
    func startAfterEndIsNotPeriod() {
        #expect(throws: ReadingPeriod.ValidationError.startAfterEnd) {
            try makePeriod(start: Self.yesterday, end: Self.threeDaysAgo)
        }
    }

    @Test(
        "오늘 이후 날짜는 넣을 수 없다",
        arguments: [
            (tomorrow, nil),  // 시작일이 내일이다
            (nil, tomorrow)   // 종료일이 내일이다
        ] as [(Date?, Date?)]
    )
    func futureDateIsRejected(start: Date?, end: Date?) {
        #expect(throws: ReadingPeriod.ValidationError.futureDate) {
            try makePeriod(start: start, end: end)
        }
    }

    @Test("오늘 날짜면 시각이 기준보다 늦어도 넣을 수 있다")
    func laterTimeTodayIsAllowed() throws {
        // 서울 시각 19:13. UTC로 보면 기준일 다음 날이라, 시각으로 비교하면 막힌다.
        let laterToday = Date(timeIntervalSince1970: 1_700_043_200)

        let period = try makePeriod(start: nil, end: laterToday)

        #expect(period.end == laterToday)
    }

    // MARK: - 독서 상태에 맞추기

    @Test("읽는 중이면 시작일만 남긴다")
    func watchingKeepsOnlyStart() throws {
        let period = try makePeriod(start: Self.threeDaysAgo, end: Self.yesterday)

        let normalized = period.normalized(for: .watching)

        #expect(normalized?.start == Self.threeDaysAgo)
        #expect(normalized?.end == nil)
    }

    @Test("다 읽음이면 빈 쪽을 채운다")
    func watchedFillsMissingSide() throws {
        let period = try makePeriod(start: Self.threeDaysAgo, end: nil)

        let normalized = period.normalized(for: .watched)

        #expect(normalized?.start == Self.threeDaysAgo)
        #expect(normalized?.end == Self.threeDaysAgo)
    }

    @Test("하차면 종료일만 남긴다")
    func quitKeepsOnlyEnd() throws {
        let period = try makePeriod(start: Self.threeDaysAgo, end: Self.yesterday)

        let normalized = period.normalized(for: .quit)

        #expect(normalized?.start == nil)
        #expect(normalized?.end == Self.yesterday)
    }

    // MARK: - Helpers

    private func makePeriod(start: Date?, end: Date?) throws -> ReadingPeriod {
        try ReadingPeriod(start: start, end: end, notAfter: Self.today, calendar: Self.seoul)
    }
}
