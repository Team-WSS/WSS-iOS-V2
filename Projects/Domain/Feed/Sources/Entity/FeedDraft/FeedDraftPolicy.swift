//
//  FeedDraftPolicy.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public extension FeedDraftEntity {
   
    static let maxContentCount: Int = 2000
    
    var contentCount: Int {
        content.count
    }
    
    var remainingContentCount: Int {
        Self.maxContentCount - contentCount
    }
    
    // 피드 제출 유효성 검증 기준
    
    var isSubmittable: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && genre.count > 0
    }
}
