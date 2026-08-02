//
//  LibraryDateFormatter.swift
//  LibraryFeature
//
//  Created by YunhakLee on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

/// 서재 셀의 독서 기간 표기(yy.MM.dd). 표기는 View 몫이라 Feature에 둔다.
enum LibraryDateFormatter {

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy.MM.dd"
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter
    }()

    /// 기간 표기 — 둘 다 있으면 "시작 ~ 종료", 하나만 있으면 그 날짜만, 둘 다 없으면 nil.
    /// (날짜 채움 규칙은 도메인 `ReadingPeriod.normalized(for:)`가 강제 — status로 분기하지 않는다.)
    static func text(for period: ReadingPeriod?) -> String? {
        guard let period else { return nil }
        switch (period.start, period.end) {
        case let (start?, end?):
            return "\(formatter.string(from: start)) ~ \(formatter.string(from: end))"
        case let (start?, nil):
            return formatter.string(from: start)
        case let (nil, end?):
            return formatter.string(from: end)
        case (nil, nil):
            return nil
        }
    }
}
