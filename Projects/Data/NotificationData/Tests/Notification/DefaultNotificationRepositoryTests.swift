//
//  DefaultNotificationRepositoryTests.swift
//  NotificationData
//
//  Created by YunhakLee on 3/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Testing
@testable import NotificationData
@testable import NotificationDataTesting
import NotificationDomain
import BaseDomain
import Networking

@Suite("DefaultNotificationRepository")
struct DefaultNotificationRepositoryTests {

    // MARK: - Helpers

    private func makeRepository(
        service: MockNotificationService
    ) -> DefaultNotificationRepository {
        DefaultNotificationRepository(
            notificationService: service,
            logger: nil
        )
    }

    private func makeNotificationID() -> NotificationID {
        NotificationID(1)
    }

    private func makeNotificationsResponse() -> PagedNotificationsResponse {
        PagedNotificationsResponse(isLoadable: false, notifications: [])
    }

    private func makePagedNotifications() -> PagedNotifications {
        PagedNotifications(items: [], isLoadable: false)
    }

    private func makeDetailResponse() -> NotificationDetailResponse {
        NotificationDetailResponse(
            notificationTitle: "Title",
            notificationCreatedDate: "Date",
            notificationDetail: "Detail"
        )
    }

    private func makeNotificationDetail() -> NotificationDetail {
        NotificationDetail(
            title: "Title",
            createdAtText: "Date",
            body: "Detail"
        )
    }

    private func makeUnreadStatusResponse() -> NotificationUnreadStatusResponse {
        NotificationUnreadStatusResponse(hasUnreadNotifications: true)
    }

    private func makeUnreadStatus() -> UnreadNotificationStatus {
        UnreadNotificationStatus(hasUnreadNotifications: true)
    }

    // MARK: - loadNotifications

    @Test("알림 목록 조회 성공 시 PagedNotifications 반환")
    func loadsNotificationsSuccessfully() async throws {
        let service = MockNotificationService()
        service.getNotificationsResult = .success(makeNotificationsResponse())

        let sut = makeRepository(service: service)

        let result = try await sut.loadNotifications(lastNotificationID: nil, size: 10)

        #expect(result == makePagedNotifications())
        #expect(service.requestedQuery?.lastNotificationId == 0)
        #expect(service.requestedQuery?.size == 10)
    }

    @Test("알림 목록 조회 중 networking 에러 발생 시 변환")
    func translatesNetworkingErrorOnLoadNotifications() async {
        let service = MockNotificationService()

        service.getNotificationsResult = .failure(
            NetworkingError.responseFailure(code: 401, body: nil)
        )

        let sut = makeRepository(service: service)

        await #expect(throws: RepositoryError.authenticationRequired) {
            _ = try await sut.loadNotifications(lastNotificationID: nil, size: 10)
        }
    }

    @Test("알림 목록 조회 중 unknown 에러 발생 시 unknown 반환")
    func throwsUnknownOnLoadNotifications() async {
        let service = MockNotificationService()

        service.getNotificationsResult = .failure(MockError.sample)

        let sut = makeRepository(service: service)

        await #expect(throws: RepositoryError.unknown) {
            _ = try await sut.loadNotifications(lastNotificationID: nil, size: 10)
        }
    }

    // MARK: - loadNotificationDetail

    @Test("알림 상세 조회 성공 시 NotificationDetail 반환")
    func loadsNotificationDetailSuccessfully() async throws {
        let service = MockNotificationService()

        service.getNotificationDetailResult = .success(makeDetailResponse())

        let sut = makeRepository(service: service)

        let id = makeNotificationID()
        let result = try await sut.loadNotificationDetail(id: id)

        #expect(result == makeNotificationDetail())
        #expect(service.requestedDetailID == id.value)
    }

    @Test("알림 상세 조회 중 networking 에러 처리")
    func translatesNetworkingErrorOnLoadDetail() async {
        let service = MockNotificationService()

        service.getNotificationDetailResult = .failure(
            NetworkingError.responseFailure(code: 404, body: nil)
        )

        let sut = makeRepository(service: service)

        await #expect(throws: RepositoryError.notFound) {
            _ = try await sut.loadNotificationDetail(id: makeNotificationID())
        }
    }

    // MARK: - markAsRead

    @Test("알림 읽음 처리 성공 시 service 호출됨")
    func marksAsReadSuccessfully() async throws {
        let service = MockNotificationService()

        let sut = makeRepository(service: service)
        let id = makeNotificationID()

        try await sut.markAsRead(id: id)

        #expect(service.markedAsReadID == id.value)
    }

    @Test("읽음 처리 중 networking 에러 처리")
    func translatesNetworkingErrorOnMarkAsRead() async {
        let service = MockNotificationService()

        service.postNotificationReadResult = .failure(
            NetworkingError.responseFailure(code: 500, body: nil)
        )

        let sut = makeRepository(service: service)

        await #expect(throws: RepositoryError.serverUnavailable) {
            try await sut.markAsRead(id: makeNotificationID())
        }
    }

    // MARK: - loadUnreadNotificationStatus

    @Test("읽지 않은 알림 상태 조회 성공")
    func loadsUnreadStatusSuccessfully() async throws {
        let service = MockNotificationService()

        service.getUnreadStatusResult = .success(makeUnreadStatusResponse())

        let sut = makeRepository(service: service)

        let result = try await sut.loadUnreadNotificationStatus()

        #expect(result == makeUnreadStatus())
    }

    @Test("읽지 않은 알림 상태 조회 중 networking 에러 처리")
    func translatesNetworkingErrorOnUnreadStatus() async {
        let service = MockNotificationService()

        service.getUnreadStatusResult = .failure(
            NetworkingError.responseFailure(code: 401, body: nil)
        )

        let sut = makeRepository(service: service)

        await #expect(throws: RepositoryError.authenticationRequired) {
            _ = try await sut.loadUnreadNotificationStatus()
        }
    }
}
