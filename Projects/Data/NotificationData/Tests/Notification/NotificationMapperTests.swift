//
//  NotificationMapperTests.swift
//  NotificationData
//
//  Created by YunhakLee on 8/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Testing
@testable import NotificationData
import NotificationDomain
import BaseDomain

/// 알림 응답 → 딥링크 매핑. 이 분기가 화면 전환의 전부를 결정하고,
/// 세 ID 타입이 컴파일러에겐 같은 타입(`IDWrapper<Int>`)이라 잘못 매핑돼도 컴파일은 통과한다.
@Suite("NotificationMapper")
struct NotificationMapperTests {

    // MARK: - Helpers

    private func makeResponse(
        isNotice: Bool,
        feedId: Int? = nil,
        novelId: Int? = nil
    ) -> NotificationResponse {
        NotificationResponse(
            notificationId: 1,
            notificationImage: "/notification-type/notice",
            notificationTitle: "제목",
            notificationBody: "본문",
            createdDate: "2026.08.22",
            isRead: false,
            isNotice: isNotice,
            feedId: feedId,
            novelId: novelId
        )
    }

    // MARK: - 딥링크 매핑

    @Test("공지 알림은 알림 상세 딥링크가 된다")
    func noticeMapsToNotificationDetail() {
        let item = NotificationMapper.notificationItem(from: makeResponse(isNotice: true))

        #expect(item.deeplink == .notificationDetail(id: NotificationID(1)))
    }

    @Test("feedId가 있는 알림은 피드 상세 딥링크가 된다")
    func feedIDMapsToFeedDetail() {
        let item = NotificationMapper.notificationItem(from: makeResponse(isNotice: false, feedId: 7))

        #expect(item.deeplink == .feedDetail(id: FeedID(7)))
    }

    @Test("novelId가 있는 알림(완결·휴재 복귀)은 작품 상세 딥링크가 된다")
    func novelIDMapsToNovelDetail() {
        let item = NotificationMapper.notificationItem(from: makeResponse(isNotice: false, novelId: 4217))

        #expect(item.deeplink == .novelDetail(id: NovelID(4217)))
    }

    @Test("가리키는 대상이 없는 알림은 unknown 딥링크가 된다")
    func noTargetMapsToUnknown() {
        let item = NotificationMapper.notificationItem(from: makeResponse(isNotice: false))

        #expect(item.deeplink == .unknown)
    }

    /// 분기 우선순위 고정 — 작품 알림은 `isNotice: false`로 온다는 서버 스펙에 기대고 있다.
    /// 서버가 작품 알림에도 `isNotice: true`를 주기 시작하면 이 테스트가 그 변화를 먼저 알린다.
    @Test("공지 플래그가 켜져 있으면 novelId가 있어도 알림 상세로 간다")
    func noticeTakesPrecedenceOverNovelID() {
        let item = NotificationMapper.notificationItem(from: makeResponse(isNotice: true, novelId: 4217))

        #expect(item.deeplink == .notificationDetail(id: NotificationID(1)))
    }
}
