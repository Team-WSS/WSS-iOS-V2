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

    /// 분기 우선순위를 **의도적으로 고정**한다 — 매퍼는 **id 존재를 isNotice보다 먼저** 본다.
    /// 완결 알림이 `isNotice: true`로 와도 novelId가 있으면 작품 상세로 가야 한다("novelId 있으면 다 작품 상세" 규칙).
    /// 순수 공지(id 없음)만 isNotice로 알림 상세로 간다.
    @Test("novelId가 있으면 공지 플래그가 켜져 있어도 작품 상세로 간다")
    func novelIDTakesPrecedenceOverNotice() {
        let item = NotificationMapper.notificationItem(from: makeResponse(isNotice: true, novelId: 4217))

        #expect(item.deeplink == .novelDetail(id: NovelID(4217)))
    }

    @Test("feedId가 있으면 공지 플래그가 켜져 있어도 피드 상세로 간다")
    func feedIDTakesPrecedenceOverNotice() {
        let item = NotificationMapper.notificationItem(from: makeResponse(isNotice: true, feedId: 7))

        #expect(item.deeplink == .feedDetail(id: FeedID(7)))
    }
}
