//
//  NotificationListRoute.swift
//  NotificationFeature
//
//  Created by YunhakLee on 9/8/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain

/// 알림 목록 화면이 밖(App 조정 계층)으로 요청하는 화면 전환의 전부 — #253.
/// 케이스는 알림 딥링크 종류를 그대로 따른다(`.unknown`은 전환이 없어 여기 없음 — 읽음 처리만 한다).
public enum NotificationListRoute {
    /// 알림 상세 — 알림 상세 딥링크(`.notificationDetail`) 셀 탭.
    case notificationDetail(NotificationID)
    /// 피드 상세 — 피드 딥링크(`.feedDetail`) 셀 탭.
    case feedDetail(FeedID)
    /// 작품 상세 — 작품 딥링크(`.novelDetail`) 셀 탭. 완결·휴재 복귀 알림이 응답의 `novelId`로 실린다(#181).
    case novelDetail(NovelID)
}
