//
//  DetailSearchResultRoute.swift
//  SearchFeature
//
//  Created by YunhakLee on 9/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain

/// 상세탐색 결과 화면이 밖(App 조정 계층)으로 요청하는 화면 전환의 전부 — #253.
/// 케이스가 하나뿐이어도 enum으로 통일한다 — 목적지가 늘 때 App 쪽 switch를 컴파일러가 강제하도록.
public enum DetailSearchResultRoute {
    /// 작품 상세 — 결과 그리드의 작품 셀 탭.
    case novelDetail(NovelID)
}
