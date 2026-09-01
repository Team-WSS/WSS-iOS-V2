//
//  DetailSearchFilterTab.swift
//  SearchFeature
//
//  Created by YunhakLee on 9/1/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

/// 상세탐색 필터 화면(`DetailSearchFilterView`)의 탭 — 진입 시 어느 탭을 열지 호출자(App)가
/// 지정할 수 있게 public으로 연 seam(#236). 일반 검색의 "더보기" 헤더가 진입점별로 다른 탭을
/// 요구해서다(V1 parity — 장르 더보기 → 정보 탭, 키워드 더보기 → 키워드 탭).
/// App의 `Destination` payload로도 쓰이므로 `Hashable`이어야 한다.
public enum DetailSearchFilterTab: Hashable, Sendable {
    case info
    case keyword
}
