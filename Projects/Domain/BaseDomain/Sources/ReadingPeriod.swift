//
//  ReadingPeriod.swift
//  BaseDomain
//
//  Created by YunhakLee on 1/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct ReadingPeriod: Equatable {
    public let start: Date?
    public let end: Date?
    
    // MARK: - Policy
    
    /// 독서 기간 불변식을 강제한다.
    /// - 미래 날짜 불가: 시작/종료 어느 쪽도 `notAfter`(기본 오늘) 이후일 수 없다. ("읽지 않은 미래"는 표현 불가능)
    /// - `start <= end`.
    /// - 적어도 한쪽은 존재.
    ///
    /// `notAfter` 비교는 **일(day) 단위**다. 순간 단위로 비교하면 자정 근처에서 같은 날 날짜가 미래로 오판된다.
    public init(start: Date?, end: Date?, notAfter limit: Date = Date()) throws {
        let calendar = Calendar.current
        func isAfterLimit(_ date: Date) -> Bool {
            calendar.compare(date, to: limit, toGranularity: .day) == .orderedDescending
        }
        if let start, isAfterLimit(start) {
            throw ValidationError.futureDate
        }
        if let end, isAfterLimit(end) {
            throw ValidationError.futureDate
        }
        if let start, let end {
            guard start <= end else {
                throw ValidationError.startAfterEnd
            }
        }
        guard start != nil || end != nil else {
            throw ValidationError.invalidPeriod
        }
        self.start = start
        self.end = end
    }

    public enum ValidationError: Error, Equatable {
        case invalidPeriod
        case startAfterEnd
        case futureDate
    }
    
    // MARK: - Normalize
    
    public func normalized(for status: ReadingStatus) -> ReadingPeriod? {
        switch status {
        case .watching:
            // 시작일이 있으면 유지, 없으면 종료일을 시작일로 끌어다 쓰고 종료일은 비움
            guard let s = start ?? end else { return nil }
            return try? ReadingPeriod(start: s, end: nil)
            
        case .watched:
            // 둘 다 있어야 함. 하나만 있다면 그걸로 시작/종료를 다 채워버리는 정책
            let s = start ?? end
            let e = end ?? start
            guard let finalStart = s, let finalEnd = e else { return nil }
            return try? ReadingPeriod(start: finalStart, end: finalEnd)
            
        case .quit:
            // 종료일이 있으면 유지, 없으면 시작일을 종료일로 쓰고 시작일은 비움
            guard let e = end ?? start else { return nil }
            return try? ReadingPeriod(start: nil, end: e)
        }
    }
}
