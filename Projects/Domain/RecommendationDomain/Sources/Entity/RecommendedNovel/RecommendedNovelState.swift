//
//  RecommendedNovelState.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// 홈 - 선호 장르 기반 작품 상태

public enum RecommendedNovelState {
    case novels([RecommendedNovel])   // 데이터 있음
    case noGenreSettings              // 선호 장르 미설정
}
