//
//  WSSAlertType.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 5/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public enum WSSAlertType: CaseIterable {
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
    
    // 신고
    case reportImproperContent
    case receivedReportImproperContent
    case reportSpoilerContent
    case receivedReportSpoilerContent
    
    // 설정
    case blockUser
    case setAppNotification
    case logout
}
