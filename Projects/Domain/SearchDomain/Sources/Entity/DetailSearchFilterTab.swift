//
//  DetailSearchFilterTab.swift
//  SearchDomain
//
//  Created by YunhakLee on 9/1/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

/// 상세탐색 필터 화면의 진입 탭 — 호출자(App)가 어느 탭을 열지 지정한다(#236).
/// 일반 검색의 "더보기" 헤더가 진입점별로 다른 탭을 요구해서다(V1 parity — 장르 더보기 → 정보 탭,
/// 키워드 더보기 → 키워드 탭).
///
/// `SearchFilter`와 **같은 이유로 Feature가 아니라 이 도메인에 둔다** — App이 `Destination` enum
/// (`NavigationPath` push용)의 연관값으로 이 값을 직접 담아야 해서 `Hashable`이 필요하고, Feature 모듈의
/// public 진입점은 Factory 하나로 제한되므로(arch-lint `feature-exclusivity`) App↔Feature 값 계약은
/// Domain이 소유한다. 처음엔 `SearchFeature/Sources/Navigation/`의 public seam으로 뒀으나, 그 seam은
/// 계약 타입(typealias·protocol)만 허용이고 구체 enum은 위반이라 여기로 옮겼다.
public enum DetailSearchFilterTab: Hashable, Sendable {
    case info
    case keyword
}
