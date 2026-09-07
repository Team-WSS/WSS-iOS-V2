//
//  NovelDetailRoute.swift
//  NovelDetailFeature
//
//  Created by YunhakLee on 9/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain
import FeedDomain
import NovelDomain

/// 작품 상세 화면이 밖(App 조정 계층)으로 요청하는 화면 전환의 전부 — #253.
///
/// Feature는 이동 "의도"만 이 enum으로 올리고, 실제 화면 조립·push는 호출자(App)가
/// exhaustive switch로 수행한다. 호출자 탭에 대응 목적지가 없으면 `break`로 의도적 무시를
/// 명시한다(placeholder 클로저 ❌). 세션 이벤트(`onAuthenticationRequired`)와 완료 결과
/// 콜백은 화면 전환 의도가 아니므로 여기 넣지 않는다 — 별도 클로저 유지.
public enum NovelDetailRoute {
    /// 작품 평가 화면 — 평가 상태바 탭. `ReadingStatus`는 평가 초안에 seed할 읽기 상태
    /// (상태바에서 탭한 상태 / 평가 있음의 칩·여백 탭은 현재 상태).
    case review(NovelInformation, ReadingStatus)
    /// 피드 작성(CreateFeed) — "나도 한마디"·피드 탭 플로팅 버튼 공용. 보고 있는 작품을
    /// `ConnectedNovel`로 넘겨, 작성 화면이 그 작품이 미리 연결된 상태로 열리게 한다.
    case createFeed(ConnectedNovel)
    /// 피드 상세 — 피드 탭의 셀 탭.
    case feedDetail(FeedID)
    /// 유저 프로필 — 피드 셀 프로필 영역(이미지+닉네임) 탭(내 글이면 호출되지 않음).
    case userProfile(UserID)
    /// 작품 상세 — 피드 셀 연결 작품 배너 탭.
    case novelDetail(NovelID)
    /// 피드 수정 — 내 글 threedots 드롭다운의 "수정하기". 대상 `FeedID`만 넘긴다 —
    /// 실제 데이터 로드는 수정 화면 자신이 한다.
    case editFeed(FeedID)
    /// 작가 검색 — 헤더 작품 정보의 작가 이름 탭. 전달값은 탭한 작가 한 명의 이름.
    case authorSearch(String)
}
