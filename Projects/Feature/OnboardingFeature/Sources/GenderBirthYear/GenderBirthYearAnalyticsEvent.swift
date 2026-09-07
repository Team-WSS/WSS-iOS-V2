//
//  GenderBirthYearAnalyticsEvent.swift
//  OnboardingFeature
//
//  Created by Claude on 9/7/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Analytics

/// 성별/출생년도 단계 이벤트(#249, 전부 V1 백로그 — 실제 배포된 적 없음).
enum GenderBirthYearAnalyticsEvent: String, AnalyticsEvent {
    case maleSelected = "onboding_man"
    case femaleSelected = "onboding_woman"
    case birthYearSelected = "onboding_age"
}
