//
//  MockNotificationRepository.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import NotificationDomain
import BaseDomain

/// 알림 저장소 가짜 객체(Stub) — 호출을 기록하지 않는다.
/// 목록 조회는 **요청 개수마다** 답을 정해 둔다 — 정해 두지 않은 개수엔 빈 페이지를 준다.
/// 그래서 UseCase가 개수를 잘못 넘기면 결과가 달라진다.
/// 나머지 메서드는 이 모듈 테스트가 쓰지 않아 항상 `.unknown`을 던진다.
public final class MockNotificationRepository: NotificationRepository, @unchecked Sendable {
    public var pagesBySize: [Int: PagedNotifications] = [:]

    public init() {}

    public func loadNotifications(
        lastNotificationID: NotificationID?,
        size: Int
    ) async throws(RepositoryError) -> PagedNotifications {
        pagesBySize[size] ?? PagedNotifications(items: [], isLoadable: false)
    }

    public func loadNotificationDetail(id: NotificationID) async throws(RepositoryError) -> NotificationDetail {
        throw .unknown
    }

    public func markAsRead(id: NotificationID) async throws(RepositoryError) {
        throw .unknown
    }

    public func loadUnreadNotificationStatus() async throws(RepositoryError) -> UnreadNotificationStatus {
        throw .unknown
    }
}
