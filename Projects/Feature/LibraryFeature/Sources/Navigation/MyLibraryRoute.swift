//
//  MyLibraryRoute.swift
//  LibraryFeature
//
//  Created by YunhakLee on 9/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain

/// 내 서재(탭 콘텐츠) 화면이 밖(App 조정 계층)으로 요청하는 화면 전환의 전부 — #253.
public enum MyLibraryRoute {
    /// 작품 상세 — 작품 셀 탭.
    case novelDetail(NovelID)
    /// 검색 — 빈 상태 "웹소설 찾기" CTA.
    case search
    /// 작품 등록 — 우상단 등록 버튼. 전용 등록 화면이 없어 현재 App은 검색으로 보낸다(사용자 확정,
    /// #196) — 전용 화면이 생기면 App 쪽 이 케이스 매핑만 바꾸면 되도록 `.search`와 케이스를 분리해 둔다.
    case register
    /// 관심 작품 알림 설정 — "알림 관리"(설정 메인 목록을 거치지 않고 직행, #196).
    case notificationSetting
}
