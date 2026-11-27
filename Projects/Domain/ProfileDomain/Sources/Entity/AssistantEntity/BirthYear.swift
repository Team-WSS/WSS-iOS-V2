//
//  BirthYear.swift
//  ProfileDomain
//
//  Created by YunhakLee on 2/24/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct BirthYear: Equatable, Sendable {
    public let value: Int

    static public let minYear = 1900
    /// 생년 상한 = 현재 연도(하드코딩하지 않는다 — 해가 바뀌어도 자동 반영, #222).
    /// V1·구 V2는 고정값(2025/2024)이라 해가 지나면 stale해졌다. 생년 휠 상한이 이 값을 그대로 쓴다.
    static public var maxYear: Int {
        maxYear(today: Date(), calendar: .current)
    }

    /// `today`·`calendar`는 테스트가 올해를 고정하려고 넘긴다. 앱은 기본값(지금·기기 달력)을 쓴다.
    public init(_ value: Int, today: Date = Date(), calendar: Calendar = .current) throws {
        guard (Self.minYear...Self.maxYear(today: today, calendar: calendar)).contains(value) else {
            throw ValidationError.invalidRange
        }
        self.value = value
    }

    private static func maxYear(today: Date, calendar: Calendar) -> Int {
        calendar.component(.year, from: today)
    }
    
    public enum ValidationError: Error {
        case invalidRange
    }
}
