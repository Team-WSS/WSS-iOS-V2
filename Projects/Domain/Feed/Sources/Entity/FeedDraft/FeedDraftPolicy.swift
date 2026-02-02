//
//  FeedDraftPolicy.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public extension FeedDraft {
   
    static let maxContentCount: Int = 2000
    
    var contentCount: Int {
        content.count
    }
    
    var remainingContentCount: Int {
        Self.maxContentCount - contentCount
    }
    
    // 피드 제출 유효성 검증 기준
    var submissionValidationResult: FeedDraftSubmissionValidationResult {
        if content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .invalid(reason: .emptyContent)
        }
        
        if genre.isEmpty {
            return .invalid(reason: .emptyGenre)
        }
        
        return .valid
    }
}

// 피드 유효성 규칙
public enum FeedDraftInvalidReason: Equatable {
    case emptyContent
    case emptyGenre
}

public enum FeedDraftSubmissionValidationResult: Equatable {
    case valid
    case invalid(reason: FeedDraftInvalidReason)
}
