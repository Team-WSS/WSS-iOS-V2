//
//  LibraryRatingFilter.swift
//  NovelDomain
//
//  Created by YunhakLee on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// 서재 별점 필터.
///
/// 검색 필터의 `NovelRatingThreshold`(이상 4단계)와 달리 서재는 **범위**(min~max)와
/// **별점 없음(미평가 작품만)** 두 모드를 지원한다. 서버도 동일하게
/// `ratingMin`/`ratingMax` 또는 `unratedOnly`로 받는다 (미평가 = 0.0 규칙 공유).
public enum LibraryRatingFilter: Equatable, Hashable {
    case range(min: Float, max: Float)
    case unratedOnly
}
