//
//  SosoFeedRoute.swift
//  FeedFeature
//
//  Created by YunhakLee on 9/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain

/// 소소피드(피드 탭 콘텐츠) 화면이 밖(App 조정 계층)으로 요청하는 화면 전환의 전부 — #253.
public enum SosoFeedRoute {
    /// 피드 상세 — 피드 셀 탭(좋아요 등 안쪽 인터랙션 제외).
    case feedDetail(FeedID)
    /// 피드 작성 — 우상단 연필 아이콘.
    case createFeed
    /// 피드 수정 — 내 글 threedots 드롭다운의 "수정하기". 데이터 로드는 수정 화면 자신이 한다.
    case editFeed(FeedID)
    /// 유저 프로필 — 작성자 프로필(이미지+닉네임) 탭(내 글이면 호출되지 않음 — App도 이중 가드).
    case userProfile(UserID)
    /// 작품 상세 — 연결 작품 배너 탭.
    case novelDetail(NovelID)
}
