//
//  WSSAlertType.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 5/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public enum WSSAlertType: CaseIterable {
    case needTermsAgreement
    case needVersionUpdate
    
    case stopNovelReview
    case deleteNovelReviewDate
    case deleteNovelReview
    
    case deleteMyFeed
    case deleteMyComment
    
    case alreadyDeletedFeed
    
    case reportImproperContent
    case receivedReportImproperContent
    case reportSpoilerContent
    case receivedReportSpoilerContent
    
    case stopWritingFeed
    
    case blockUser
    case setAppNotification
    case logout
}
