//
//  LibrarySortType+Library.swift
//  LibraryFeature
//
//  Created by YunhakLee on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import NovelDomain

// 정렬 카피 — 메인 정렬 버튼과 정렬 시트가 공용. (도메인 의미값 → 카피 매핑은 View 몫)
extension LibrarySortType {
    /// 정렬 시트 행 라벨.
    var libraryDisplayName: String {
        switch self {
        case .registeredNewest: "등록 최신순"
        case .registeredOldest: "등록 오래된순"
        case .title:            "제목순"
        case .readDate:         "날짜순"
        case .ratingHighest:    "별점 높은순"
        case .ratingLowest:     "별점 낮은순"
        }
    }

    /// 메인 화면 정렬 버튼의 축약 라벨 — 디자인은 "최신순"으로 짧게 표기.
    var libraryShortDisplayName: String {
        switch self {
        case .registeredNewest: "최신순"
        case .registeredOldest: "오래된순"
        case .title:            "제목순"
        case .readDate:         "날짜순"
        case .ratingHighest:    "별점 높은순"
        case .ratingLowest:     "별점 낮은순"
        }
    }
}
