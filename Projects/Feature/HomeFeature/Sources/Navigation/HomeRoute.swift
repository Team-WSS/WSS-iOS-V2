//
//  HomeRoute.swift
//  HomeFeature
//
//  Created by YunhakLee on 9/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain

/// 홈(탭 콘텐츠) 화면이 밖(App 조정 계층)으로 요청하는 화면 전환의 전부 — #253.
public enum HomeRoute {
    /// 작품 상세 — 추천/탐색 섹션의 작품 셀 탭.
    case novelDetail(NovelID)
    /// 피드 상세 — 인기 피드 셀 탭.
    case feedDetail(FeedID)
    /// 일반 검색 — 상단 검색바 탭.
    case search
    /// 상세탐색 — "뭐 읽을지 고민될 때?" 배너 탭. 어느 탭으로 열지(.info)는 App이 정한다.
    case detailSearch
    /// 알림 목록 — 알림 벨 탭(권한 denied 알럿 사이드이펙트도 App이 목적지 쪽에서 처리 — App/CLAUDE.md).
    case notification
    /// 선호장르 설정 — 미설정 유도 CTA 탭(전용 화면이 없어 App은 마이페이지 편집으로 보낸다, 사용자 확정).
    case preferenceGenreSetting
}
