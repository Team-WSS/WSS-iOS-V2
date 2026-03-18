//
//  InterestFeedState.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// 홈 - 관심글 상태

public enum InterestFeedState {
    case feeds([InterestFeed])
    case noInterestSettings   // 관심 설정 안 함
    case noAssociatedFeeds    // 관련 피드 없음
}
