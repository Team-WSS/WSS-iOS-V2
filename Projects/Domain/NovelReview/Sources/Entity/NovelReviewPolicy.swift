//
//  NovelReviewPolicy.swift
//  NovelReviewDomain
//
//  Created by YunhakLee on 1/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Foundation

public extension NovelReview {
    static let maxCharmPoints = 3
    static let maxKeywords = 20

    // MARK: - Selection limits
    
    var canAddCharmPoint: Bool {
        return self.charmPoints.count < Self.maxCharmPoints
    }
    
    var canAddKeyword: Bool {
        return self.keywords.count < Self.maxKeywords
    }

    
    // MARK: - Period rules (상태별 날짜 규칙)
   
    var isPeriodValidForStatus: Bool {
        guard let period else { return true}
        
        switch status {
        case .watching: return period.start != nil && period.end == nil
        case .watched: return period.start != nil && period.end != nil
        case .quit: return period.start == nil && period.end != nil
        }
    }
    
    
    var isValidForSubmit: Bool {
        canAddKeyword && canAddCharmPoint && isPeriodValidForStatus
    }
}
