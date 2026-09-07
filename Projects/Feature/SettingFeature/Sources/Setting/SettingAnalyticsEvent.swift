//
//  SettingAnalyticsEvent.swift
//  SettingFeature
//
//  Created by Claude on 9/7/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import ProfileDomain
import Analytics

/// 설정 트리 전체가 공유하는 이벤트 이름 카탈로그(#249).
enum SettingAnalyticsEvent: String, AnalyticsEvent {
    /// 로그아웃 버튼 클릭(확정)
    case logoutTapped = "logout"
    /// 회원탈퇴 버튼 클릭(확정)
    case withdrawTapped = "withdraw"
    /// 프로필 편집 — 남자 선택(백로그)
    case genderMaleSelected = "mypage_man"
    /// 프로필 편집 — 여자 선택(백로그)
    case genderFemaleSelected = "mypage_woman"
    /// 프로필 편집 — 나이(출생연도) 선택(백로그)
    case birthYearSelected = "mypage_age"

    init(gender: Gender) {
        self = gender == .male ? .genderMaleSelected : .genderFemaleSelected
    }
}
