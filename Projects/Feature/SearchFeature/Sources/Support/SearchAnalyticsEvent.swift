//
//  SearchAnalyticsEvent.swift
//  SearchFeature
//
//  Created by Claude on 9/7/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Analytics

/// 이 모듈(일반 검색·상세탐색 결과·상세탐색 필터) 전체가 공유하는 이벤트 이름 카탈로그(#249).
/// 화면이 셋이라도 한 파일로 두는 이유는 `Feature CLAUDE.md` 파일 배치 규칙(타입별 분리 ❌)과 같은 결 —
/// "이 모듈의 이벤트 전부"를 한눈에 보는 게 화면별로 쪼개는 것보다 유용하다.
enum SearchAnalyticsEvent: String, AnalyticsEvent {
    /// 일반 검색(`NormalSearchView`) 진입
    case screenViewed = "search"
    /// 검색 실행(결과 화면으로 전환)
    case resultViewed = "search_result"
    /// 일반 검색 결과 셀 클릭
    case resultSelected = "click_search_result"
    /// 검색 결과 없을 때 "찾는 작품이 없다면?" 문의 클릭(일반 검색·상세탐색 결과 공용)
    case contactNovelTapped = "contact_novel_search"
    /// 소소 pick! 작품 클릭
    case sosoPickSelected = "soso_pick"
    /// 상세탐색 결과(`DetailSearchResultView`) 진입
    case detailResultViewed = "seek_result"
    /// 상세탐색 결과 셀 클릭
    case detailResultSelected = "click_seek_result"
    /// 상세탐색 필터 — 정보탭 장르 선택(백로그)
    case infoGenreSelected = "seek_info_genre"
    /// 상세탐색 필터 — 정보탭 연재상태 선택(백로그)
    case infoPublicationStatusSelected = "seek_info_state"
    /// 상세탐색 필터 — 정보탭 별점 범위 조정(백로그)
    case infoRatingChanged = "seek_info_rating"

    // ⚠️ "탐색 > 세계관/소재/캐릭터/관계/분위기 키워드 선택"(seek_keyword_*, 5종)과 "키워드 문의하러
    // 가기"(contact_keyword)는 이 모듈 안에서 발화되지 않는다 — 상세탐색 필터의 "키워드" 탭 콘텐츠는
    // `KeywordFeature`(App이 조립)가 소유해 이 enum이 그 선택을 못 본다. 실제 트래킹은 App의
    // `SearchAssembly.makeDetailSearchFilterView`가 같은 문자열을 직접 들고 한다(arch-lint
    // `feature-exclusivity`가 이 enum을 App에 노출 못 하게 막아서 — `NovelReviewAssembly`와 동일 이유).
    // **여기 문자열을 바꾸면 그쪽도 같이 바꿔야 한다**(수동 동기화, 컴파일러가 못 잡아줌):
    // seek_keyword_universe/topic/character/relation/mood, contact_keyword.
}
