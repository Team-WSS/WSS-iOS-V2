//
//  LibraryFilterTests.swift
//  NovelDomain
//
//  Created by YunhakLee on 11/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

import NovelDomain

@Suite("다른 사람 서재 필터")
struct LibraryFilterTests {

    @Test("다른 사람 서재의 초기 정렬 타입은 등록 최신순이다")
    func startsWithRegisteredNewest() {
        let filter = LibraryFilter()

        #expect(filter.sortType == .registeredNewest)
    }

    @Test("다른 사람 서재의 정렬 타입을 변경할 수 있다")
    func keepsChangedSortType() {
        var filter = LibraryFilter()

        filter.setSortType(.title)

        #expect(filter.sortType == .title)
    }
}
