//
//  BirthYearTests.swift
//  ProfileDomain
//
//  Created by YunhakLee on 11/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

import ProfileDomain

// 상한은 고정값이 아니라 올해다(#222 — 하드코딩하면 해가 바뀔 때마다 낡는다).
// 테스트는 오늘을 2026년 6월 1일(서울)로 고정한다 — 기대값을 소스의 `maxYear`에서 가져오면 상한이 틀려도 함께 틀려 못 잡는다.
private let seoul: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
    return calendar
}()
private let today = seoul.date(from: DateComponents(year: 2026, month: 6, day: 1))!

@Suite("생년")
struct BirthYearTests {

    @Test(
        "1900년부터 올해까지는 생년으로 고를 수 있다",
        arguments: [
            1900, // 가장 이른 해
            2026 // 올해
        ]
    )
    func acceptsYearsInRange(year: Int) throws {
        let birth = try BirthYear(year, today: today, calendar: seoul)

        #expect(birth.value == year)
    }

    @Test(
        "1900년 전이나 올해 뒤는 생년으로 고를 수 없다",
        arguments: [
            1900 - 1, // 가장 이른 해 바로 전
            2027 // 내년
        ]
    )
    func rejectsYearsOutOfRange(year: Int) {
        #expect(throws: BirthYear.ValidationError.invalidRange) {
            try BirthYear(year, today: today, calendar: seoul)
        }
    }
}
