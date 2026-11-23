//
//  BirthYearTests.swift
//  ProfileDomain
//
//  Created by YunhakLee on 11/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

import ProfileDomain

// 상한은 고정값이 아니라 올해다(#222 — 하드코딩하면 해가 바뀔 때마다 낡는다). 테스트는 시계를 직접 읽지 않고
// `BirthYear.maxYear`로 올해를 받는다.
@Suite("생년")
struct BirthYearTests {

    @Test(
        "1900년부터 올해까지는 생년으로 고를 수 있다",
        arguments: [
            1900, // 가장 이른 해
            BirthYear.maxYear
        ]
    )
    func acceptsYearsInRange(year: Int) throws {
        let birth = try BirthYear(year)

        #expect(birth.value == year)
    }

    @Test(
        "1900년 전이나 올해 뒤는 생년으로 고를 수 없다",
        arguments: [
            1900 - 1, // 가장 이른 해 바로 전
            BirthYear.maxYear + 1 // 내년
        ]
    )
    func rejectsYearsOutOfRange(year: Int) {
        #expect(throws: BirthYear.ValidationError.invalidRange) {
            try BirthYear(year)
        }
    }
}
