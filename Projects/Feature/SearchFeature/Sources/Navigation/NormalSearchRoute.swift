//
//  NormalSearchRoute.swift
//  SearchFeature
//
//  Created by YunhakLee on 9/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain
import SearchDomain

/// 일반 검색 화면이 밖(App 조정 계층)으로 요청하는 화면 전환의 전부 — #253.
/// 실제 화면 조립·push는 호출자(App)가 exhaustive switch로 수행한다(패턴 정본:
/// `NovelDetailFeature/Sources/Navigation/NovelDetailRoute.swift`).
public enum NormalSearchRoute {
    /// 작품 상세 — 검색 결과·소소픽 작품 셀 탭.
    case novelDetail(NovelID)
    /// 상세탐색 결과(`makeDetailSearchResultView`) — 장르 탭·인기 키워드 칩 탭.
    /// `NavigationPath` 혼용으로 화면이 안 쌓이는 문제 때문에 App이 직접 push해야 한다
    /// (`SearchAssembly` 상단 주의사항 참고).
    case detailSearchResult(SearchFilter)
    /// 상세탐색 **필터 화면**(`makeDetailSearchFilterView`) — 장르·키워드 섹션 "더보기" 헤더(#236,
    /// V1 parity). 어느 탭으로 열지를 함께 넘긴다(장르 더보기 → `.info`, 키워드 더보기 → `.keyword`).
    case detailSearchFilter(DetailSearchFilterTab)
}
