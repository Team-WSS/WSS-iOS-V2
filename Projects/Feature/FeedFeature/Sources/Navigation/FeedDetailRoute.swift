//
//  FeedDetailRoute.swift
//  FeedFeature
//
//  Created by YunhakLee on 9/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain

/// 피드 상세 화면이 밖(App 조정 계층)으로 요청하는 화면 전환의 전부 — #253.
public enum FeedDetailRoute {
    /// 작품 상세 — 연결 작품 배너 탭.
    case novelDetail(NovelID)
    /// 피드 수정 — 내 글 threedots 드롭다운의 "수정하기".
    case editFeed(FeedID)
    /// 유저 프로필 — 작성자·댓글 프로필 탭(내 글/댓글이면 호출되지 않음).
    case userProfile(UserID)
}
