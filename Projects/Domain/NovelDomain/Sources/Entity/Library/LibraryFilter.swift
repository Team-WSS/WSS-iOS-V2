//
//  LibraryFilter.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

/// 타유저 서재 조회 필터.
///
/// 내 서재(`MyLibraryFilter`)와 달리 **정렬만** 담는다 — 타유저 서재 화면엔 필터 UI가 없다(디자인).
/// 정렬 종류는 내 서재와 같은 `LibrarySortType`(6종)이다. 같은 V2 엔드포인트
/// (`/users/{userId}/novels/v2`)를 userID만 바꿔 호출하기 때문.
public struct LibraryFilter: Equatable, Sendable {

    public private(set) var sortType: LibrarySortType

    public init(sortType: LibrarySortType = .registeredNewest) {
        self.sortType = sortType
    }

    // MARK: - Policy

    public mutating func setSortType(_ sortType: LibrarySortType) {
        self.sortType = sortType
    }
}
