//
//  ReadingPeriod+Presentation.swift
//  WSSComponent
//
//  Created by Guryss on 8/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public extension ReadingPeriod {

    /// 독서 기간 표기(yy.MM.dd) — 둘 다 있으면 "시작 ~ 종료", 하나만 있으면 그 날짜만, 둘 다 없으면 nil.
    /// (날짜 채움 규칙은 도메인 `ReadingPeriod.normalized(for:)`가 강제 — status로 분기하지 않는다.)
    /// 원본은 `LibraryFeature`의 `LibraryDateFormatter` — 서재 그리드/리스트 셀과 컬렉션 "서재에서
    /// 추가" 화면이 같은 표기를 쓰게 돼 공용화했다(2026-08).
    var displayText: String? {
        switch (start, end) {
        case let (start?, end?):
            return "\(Self.formatter.string(from: start)) ~ \(Self.formatter.string(from: end))"
        case let (start?, nil):
            return Self.formatter.string(from: start)
        case let (nil, end?):
            return Self.formatter.string(from: end)
        case (nil, nil):
            return nil
        }
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy.MM.dd"
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter
    }()
}
