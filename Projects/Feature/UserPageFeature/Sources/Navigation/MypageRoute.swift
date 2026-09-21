//
//  MypageRoute.swift
//  UserPageFeature
//
//  Created by YunhakLee on 9/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain

/// 마이페이지(My 탭 콘텐츠) 화면이 밖(App 조정 계층)으로 요청하는 화면 전환의 전부 — #253.
public enum MypageRoute {
    /// 내 컬렉션 목록 — 컬렉션 섹션 헤더 행 탭.
    case collectionList
    /// 컬렉션 상세 — 컬렉션 미리보기 항목 탭(`.collectionList`와 별개 진입).
    case collectionDetail(CollectionID)
    /// 프로필 편집.
    case editProfile
    /// 설정 — 우측 상단 톱니바퀴.
    case setting
    /// "서재" 탭으로 전환 — 내 서재 블록 탭. **push가 아니라 탭 전환**이라 App은 `path.append`가 아니라
    /// `MainTabView.selectedTab` 변경으로 매핑한다(모듈명·Factory명 혼동 주의는 `App/CLAUDE.md`).
    case libraryTab
}
