//
//  NovelNotificationSetting.swift
//  NotificationDomain
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

/// 작품 하나에 대한 완결/휴재복귀 알림 on-off 값 — 작품 상세의 종 모양 아이콘 시트에서 쓴다.
/// 같은 폴더의 `NovelNotificationSubscription`(구독 **목록** 항목)과는 다른 개념이다 — 이쪽은 특정
/// 작품 하나의 현재 알림 설정 상태만 다룬다(`NovelNotificationRepository`가 목록·설정 둘 다 관리).
public struct NovelNotificationSetting: Equatable, Sendable {
    public let isCompletionNotificationEnabled: Bool
    public let isHiatusReturnNotificationEnabled: Bool

    public init(
        isCompletionNotificationEnabled: Bool,
        isHiatusReturnNotificationEnabled: Bool
    ) {
        self.isCompletionNotificationEnabled = isCompletionNotificationEnabled
        self.isHiatusReturnNotificationEnabled = isHiatusReturnNotificationEnabled
    }
}
