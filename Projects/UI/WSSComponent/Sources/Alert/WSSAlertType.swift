//
//  WSSAlertType.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 5/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public enum WSSAlertType: Hashable {
    // 앱 관리
    case needTermsAgreement
    case needVersionUpdate

    // 작품 평가
    case stopNovelReview
    case deleteNovelReviewDate
    case deleteNovelReview

    // 피드
    case deleteMyFeed
    case deleteMyComment
    case alreadyDeletedFeed
    case stopWritingFeed

    // 컬렉션
    case stopWritingCollection
    case deleteCollection

    // 신고
    case reportImproperContent
    case receivedReportImproperContent
    case reportSpoilerContent
    case receivedReportSpoilerContent

    // 설정
    case blockUser
    case setAppNotification
    case logout

    // 작품 알림 구독
    /// `summary`: "제목 외 N작품" 형태로 호출부가 미리 조합해 넘긴다(복수 선택 요약은 화면마다 다를 수 있어 컴포넌트가 판단하지 않는다).
    case deleteNovelNotificationSubscriptions(summary: String)
}

// MARK: - CaseIterable

extension WSSAlertType: CaseIterable {
    /// `deleteNovelNotificationSubscriptions`가 연관값을 가져 자동 합성이 안 돼 수동으로 나열한다 —
    /// 새 정적 케이스를 추가하면 여기도 같이 채울 것(Demo 프리뷰 목록이 이걸로 채워진다).
    public static var allCases: [WSSAlertType] {
        [
            .needTermsAgreement, .needVersionUpdate,
            .stopNovelReview, .deleteNovelReviewDate, .deleteNovelReview,
            .deleteMyFeed, .deleteMyComment, .alreadyDeletedFeed, .stopWritingFeed,
            .reportImproperContent, .receivedReportImproperContent, .reportSpoilerContent, .receivedReportSpoilerContent,
            .blockUser, .setAppNotification, .logout,
            .deleteNovelNotificationSubscriptions(summary: "작품 제목 외 1작품")
        ]
    }
}
