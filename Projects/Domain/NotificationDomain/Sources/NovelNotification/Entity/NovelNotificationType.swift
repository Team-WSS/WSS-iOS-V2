//
//  NovelNotificationType.swift
//  NotificationDomain
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

/// 작품 알림 구독 종류 — 완결 알림 / 휴재 복귀 알림. 구독 목록 조회·일괄 구독 해제 둘 다 이 값으로 대상을 가른다.
public enum NovelNotificationType: Equatable, Sendable {
    case completion
    case hiatusReturn
}
