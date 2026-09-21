//
//  NovelPlatform+Search.swift
//  SearchFeature
//
//  Created by Seoyeon Choi on 8/13/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import SearchDomain

extension NovelPlatform {
    /// 상세탐색 필터 화면 카피. (WSSComponent DomainPresentation 승격은 허락 필요라 Feature-local,
    /// `NovelPublicationStatus+Search`와 동일 판단)
    ///
    /// ⚠️ UI 라벨은 "리디"지만 서버 쿼리로는 "리디북스"를 보낸다(`SearchData.SearchMapper` 참고) — 표기
    /// 불일치는 의도된 것(#185, 사용자 확정).
    var displayName: String {
        switch self {
        case .kakaoPage:    "카카오페이지"
        case .naverSeries:  "네이버시리즈"
        case .ridibooks:    "리디"
        case .munpia:       "문피아"
        case .novelpia:     "노벨피아"
        }
    }
}
