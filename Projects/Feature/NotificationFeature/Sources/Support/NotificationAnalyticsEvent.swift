//
//  NotificationAnalyticsEvent.swift
//  NotificationFeature
//
//  Created by Claude on 9/7/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Analytics

/// 이 모듈(알림 목록·상세) 전체가 공유하는 이벤트 이름 카탈로그.
enum NotificationAnalyticsEvent: String, AnalyticsEvent {
    /// 알림 목록 화면 진입
    case screenViewed = "notification_list"
    /// 알림 셀 클릭
    case notificationSelected = "notification_select"
    /// 알림 상세 화면 진입
    case detailViewed = "notification_detail"
}
