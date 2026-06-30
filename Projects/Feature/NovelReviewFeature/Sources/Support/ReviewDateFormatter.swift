//
//  ReviewDateFormatter.swift
//  NovelReviewFeature
//
//  Created by YunhakLee on 6/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// 작품 평가 화면의 날짜 표기 포맷터 모음. 디자인 표기가 고정 문구라 FormatStyle 대신 명시적 포맷을 쓴다.
enum ReviewDateFormatter {

    /// 기간 표기(`yy년 M월 d일`). 메인 화면 `periodValueLabel`용.
    static let period: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yy년 M월 d일"
        return formatter
    }()

    /// segment 표기(`yyyy-MM-dd`). 시트 watched 모드 시작/종료 탭의 보조 라벨용.
    static let segment: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
