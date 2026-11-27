//
//  MockNovelNotificationRepository.swift
//  NotificationDomain
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import NotificationDomain
import BaseDomain

/// 작품 알림 저장소 가짜 객체(Stub) — 호출을 기록하지 않는다.
/// 구독 목록 조회는 **요청 개수마다** 답을 정해 둔다 — 정해 두지 않은 개수엔 빈 페이지를 준다.
/// 그래서 UseCase가 개수를 잘못 넘기면 결과가 달라진다.
/// 나머지 메서드는 이 모듈 테스트가 쓰지 않아 항상 `.unknown`을 던진다.
public final class MockNovelNotificationRepository: NovelNotificationRepository, @unchecked Sendable {
    public var pagesBySize: [Int: PagedNovelNotificationSubscriptions] = [:]

    public init() {}

    public func loadSubscriptions(
        type: NovelNotificationType,
        lastSubscriptionID: SubscriptionID?,
        size: Int
    ) async throws(RepositoryError) -> PagedNovelNotificationSubscriptions {
        pagesBySize[size] ?? PagedNovelNotificationSubscriptions(subscriptions: [], isLoadable: false, nextSubscriptionID: nil)
    }

    public func deleteSubscriptions(type: NovelNotificationType, novelIDs: [NovelID]) async throws(RepositoryError) {
        throw .unknown
    }

    public func loadNotificationSetting(novelID: NovelID) async throws(RepositoryError) -> NovelNotificationSetting {
        throw .unknown
    }

    public func updateNotificationSetting(
        novelID: NovelID,
        setting: NovelNotificationSetting
    ) async throws(RepositoryError) {
        throw .unknown
    }
}
