//
//  NovelNotificationSubscription.swift
//  NotificationDomain
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

/// 작품 알림 구독 목록의 항목 하나 — 구독 자체의 식별자(`id`)와 대상 작품(`novelID`)을 함께 갖는다
/// (일괄 구독 해제는 `novelID` 기준으로 서버에 보낸다, `NovelNotificationRepository` 참고).
public struct NovelNotificationSubscription: Equatable {
    public let id: SubscriptionID
    public let novelID: NovelID
    public let novelTitle: String
    public let novelThumbnailImage: URL?
    public let novelAuthor: String
    /// 서버가 이미 "2026.08.06" 형식으로 포맷해 내려준다 — Domain에서 재가공하지 않는다.
    public let registeredDateText: String

    public init(
        id: SubscriptionID,
        novelID: NovelID,
        novelTitle: String,
        novelThumbnailImage: URL?,
        novelAuthor: String,
        registeredDateText: String
    ) {
        self.id = id
        self.novelID = novelID
        self.novelTitle = novelTitle
        self.novelThumbnailImage = novelThumbnailImage
        self.novelAuthor = novelAuthor
        self.registeredDateText = registeredDateText
    }
}
