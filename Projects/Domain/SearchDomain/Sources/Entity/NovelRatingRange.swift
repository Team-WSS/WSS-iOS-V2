//
//  NovelRatingRange.swift
//  SearchDomain
//
//  Created by Seoyeon Choi on 8/13/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// 상세탐색 필터(`SearchFilter`) 전용 별점 min~max 범위(0.0~5.0, 0.5 단위 11개 값).
/// `BaseDomain.NovelRatingThreshold`(단일 최소값 4단계: 3.5/4.0/4.5/4.8)와는 별개 개념 — 그쪽을
/// 대체하지 않는다. 전체 범위(0.0~5.0)는 "필터 없음"과 같은 뜻이라 `SearchFilter.setRatingRange`가
/// nil로 정규화한다(`NovelDomain.MyLibraryFilter.setRatingRange`와 동일한 규칙).
public struct NovelRatingRange: Equatable {
    public let min: Float
    public let max: Float

    public static let bounds: ClosedRange<Float> = 0.0...5.0

    public init(min: Float, max: Float) {
        self.min = min
        self.max = max
    }
}
