//
//  LibrarySortType.swift
//  NovelDomain
//
//  Created by YunhakLee on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// 서재 목록 전용 정렬.
///
/// 공용 `SortType`(최신/오래된 2종)과 달리 서재 V2 조회는 6종 정렬을 지원한다.
/// 서버 전송 문자열 매핑은 Data 레이어(Mapper) 책임.
public enum LibrarySortType: CaseIterable, Equatable, Sendable {
    case registeredNewest   // 등록 최신순
    case registeredOldest   // 등록 오래된순
    case title              // 제목순
    case readDate           // 날짜순 (읽은 날짜 기준)
    case ratingHighest      // 별점 높은순
    case ratingLowest       // 별점 낮은순
}
