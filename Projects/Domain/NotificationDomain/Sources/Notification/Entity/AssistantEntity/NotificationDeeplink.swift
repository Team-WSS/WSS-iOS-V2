//
//  NotificationDeeplink.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain

public enum NotificationDeeplink: Equatable, Sendable {
    case feedDetail(id: FeedID)
    case notificationDetail(id: NotificationID)
    /// 작품 알림(완결·휴재 복귀 등)이 향할 작품 상세.
    /// 응답의 `novelId`로 매퍼가 만든다 — 작품 알림은 `isNotice: false`로 오므로 공지 분기에 먼저 걸리지 않는다.
    case novelDetail(id: NovelID)
    case unknown
}
