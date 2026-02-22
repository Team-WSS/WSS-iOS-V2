//
//  LoadPagedNotificationsUseCaseTests.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Foundation
import Testing

import NotificationDomain
import NotificationDomainTesting
import BaseDomain


@Suite("LoadPagedNotificationsUseCase")
struct LoadPagedNotificationsUseCaseTests {

    private func makeNotificationItem(
        id: Int = 1,
        isRead: Bool = false
    ) -> NotificationItem {
        NotificationItem(
            id: NotificationID(id),
            type: .notice, // 프로젝트 enum에 맞게 수정
            iconURL: URL(string: "https://example.com/icon.png"),
            title: "테스트 알림 제목",
            body: "테스트 알림 내용입니다.",
            createdAtText: "2025.02.20",
            isRead: isRead,
            deeplink: makeDeeplink()
        )
    }

    private func makeDeeplink() -> NotificationDeeplink? {
        // 프로젝트 정의에 맞게 수정
        // 예: feed 상세로 이동하는 딥링크
        return .feedDetail(id: FeedID(100))
    }

    private func makePaged(
        count: Int = 1,
        isLoadable: Bool = true
    ) -> PagedNotifications {
        let items = (1...count).map {
            makeNotificationItem(id: $0)
        }

        return PagedNotifications(
            items: items,
            isLoadable: isLoadable
        )
    }

    @Test("lastID 이후의 알림 목록을 size 만큼 조회할 수 있다")
    func loadsNotificationsWithParameters() async throws {
        let repo = MockNotificationRepository()
        repo.loadNotificationsResult = .success(makePaged())

        let sut = DefaultLoadPagedNotificationsUseCase(repository: repo)

        let lastID = NotificationID(10)
        _ = try await sut.execute(lastNotificationID: lastID, size: 30)

        #expect(repo.loadNotificationsCallCount == 1)
        #expect(repo.loadedLastNotificationID == lastID)
        #expect(repo.loadedSize == 30)
    }

    @Test("size가 0 이하이면 기본 size(20)로 조회한다")
    func usesDefaultSizeWhenNonPositive() async throws {
        let repo = MockNotificationRepository()
        repo.loadNotificationsResult = .success(makePaged())

        let sut = DefaultLoadPagedNotificationsUseCase(repository: repo)

        _ = try await sut.execute(lastNotificationID: nil, size: 0)
        #expect(repo.loadedSize == 20)

        _ = try await sut.execute(lastNotificationID: nil, size: -1)
        #expect(repo.loadedSize == 20)
    }

    @Test("조회 중 레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockNotificationRepository()
        repo.loadNotificationsResult = .failure(.networkUnavailable)

        let sut = DefaultLoadPagedNotificationsUseCase(repository: repo)

        await #expect(throws: RepositoryError.networkUnavailable) {
            _ = try await sut.execute(lastNotificationID: nil, size: 20)
        }

        #expect(repo.loadNotificationsCallCount == 1)
    }
}
