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
    /// 응답의 `novelId`로 매퍼가 만든다 — 매퍼는 id 존재를 `isNotice`보다 우선하므로 novelId만 있으면 여기로 간다.
    case novelDetail(id: NovelID)
    case unknown
}
