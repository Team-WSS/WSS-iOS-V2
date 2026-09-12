//
//  GenreSelectionAnalyticsEvent.swift
//  OnboardingFeature
//
//  Created by Claude on 9/7/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain
import Analytics

/// 온보딩 선호장르 선택 이벤트(#249, 전부 V1 백로그 — 실제 배포된 적 없음). 장르 9종 각각 별도 이벤트.
enum GenreSelectionAnalyticsEvent: String, AnalyticsEvent {
    case romanceSelected = "onboding_prefer_R"
    case romanceFantasySelected = "onboding_prefer_RF"
    case fantasySelected = "onboding_prefer_F"
    case modernFantasySelected = "onboding_prefer_HF"
    case wuxiaSelected = "onboding_prefer_MH"
    case blSelected = "onboding_prefer_BL"
    case dramaSelected = "onboding_prefer_D"
    case mysterySelected = "onboding_prefer_M"
    case lightNovelSelected = "onboding_prefer_LN"

    init(genre: NovelGenre) {
        switch genre {
        case .romance:         self = .romanceSelected
        case .romanceFantasy:  self = .romanceFantasySelected
        case .fantasy:         self = .fantasySelected
        case .modernFantasy:   self = .modernFantasySelected
        case .wuxia:           self = .wuxiaSelected
        case .BL:               self = .blSelected
        case .drama:            self = .dramaSelected
        case .mystery:          self = .mysterySelected
        case .lightNovel:       self = .lightNovelSelected
        }
    }
}
