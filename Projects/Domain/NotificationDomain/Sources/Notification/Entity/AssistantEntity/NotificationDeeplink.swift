//
//  NotificationDeeplink.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain

public enum NotificationDeeplink: Equatable {
    case feedDetail(id: FeedID)
    case notificationDetail(id: NotificationID)
    /// 작품 알림(완결·휴재 복귀 등)이 향할 작품 상세.
    /// ⚠️ **아직 Data가 만들지 못한다** — 알림 응답에 `novelId`가 없어 서버 보강 전까지는 `.unknown`으로 떨어진다.
    /// 화면 쪽 분기를 미리 열어두려고 먼저 정의한 케이스다.
    case novelDetail(id: NovelID)
    case unknown
}
