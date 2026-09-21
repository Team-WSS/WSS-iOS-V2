//
//  UserLibraryRoute.swift
//  LibraryFeature
//
//  Created by YunhakLee on 9/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain

/// 타유저 서재(push 화면)가 밖(App 조정 계층)으로 요청하는 화면 전환의 전부 — #253.
public enum UserLibraryRoute {
    /// 작품 상세 — 작품 셀 탭.
    case novelDetail(NovelID)
}
