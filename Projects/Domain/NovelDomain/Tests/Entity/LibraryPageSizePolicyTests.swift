//
//  LibraryPageSizePolicyTests.swift
//  NovelDomain
//
//  Created by YunhakLee on 8/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import NovelDomain

@Suite
struct LibraryPageSizePolicyTests {

    // MARK: - 기본 페이지 크기

    @Test("서재 기본 요청 개수는 15개다")
    func pageSizeIsFifteen() {
        #expect(LibraryPageSizePolicy.pageSize == 15)
    }

    // MARK: - 갱신 1차 크기

    @Test("갱신은 보고 있던 개수만큼 요청한다")
    func refreshRequestsLoadedCount() {
        #expect(LibraryPageSizePolicy.refreshSize(loadedCount: 47) == 47)
    }

    @Test("아직 한 페이지도 못 받았으면 첫 페이지 크기로 요청한다")
    func refreshFallsBackToPageSize() {
        #expect(LibraryPageSizePolicy.refreshSize(loadedCount: 0) == LibraryPageSizePolicy.pageSize)
        #expect(LibraryPageSizePolicy.refreshSize(loadedCount: 7) == LibraryPageSizePolicy.pageSize)
    }

    @Test("보고 있던 개수가 서버 상한과 같으면 그대로 요청한다")
    func refreshAtExactMaxSize() {
        #expect(
            LibraryPageSizePolicy.refreshSize(loadedCount: LibraryPageSizePolicy.maxSize)
            == LibraryPageSizePolicy.maxSize
        )
    }

    @Test("보고 있던 개수가 서버 상한을 넘으면 상한에서 자른다")
    func refreshClampsToMaxSize() {
        #expect(LibraryPageSizePolicy.refreshSize(loadedCount: 140) == LibraryPageSizePolicy.maxSize)
    }

    // MARK: - 갱신 2차 크기

    @Test("자리를 비운 사이 늘어난 만큼만 이어서 요청한다")
    func followUpRequestsOnlyDelta() {
        let size = LibraryPageSizePolicy.followUpSize(
            previousTotalCount: 25,
            newTotalCount: 27,
            hasNext: true
        )
        #expect(size == 2)
    }

    @Test("늘어난 작품이 없으면 이어서 요청하지 않는다")
    func noFollowUpWhenNothingAdded() {
        #expect(LibraryPageSizePolicy.followUpSize(
            previousTotalCount: 25,
            newTotalCount: 25,
            hasNext: true
        ) == nil)
    }

    @Test("작품이 줄었으면 이어서 요청하지 않는다")
    func noFollowUpWhenDeleted() {
        // 목록이 짧아질 이유가 없으므로 보정이 필요 없다.
        #expect(LibraryPageSizePolicy.followUpSize(
            previousTotalCount: 25,
            newTotalCount: 22,
            hasNext: true
        ) == nil)
    }

    @Test("다음 페이지가 없으면 늘어났어도 이어서 요청하지 않는다")
    func noFollowUpWhenNoNextPage() {
        // 1차 응답이 이미 끝까지 받은 경우 — 이어붙일 것이 없다.
        #expect(LibraryPageSizePolicy.followUpSize(
            previousTotalCount: 25,
            newTotalCount: 27,
            hasNext: false
        ) == nil)
    }

    @Test("늘어난 개수가 서버 상한을 넘으면 상한에서 자른다")
    func followUpClampsToMaxSize() {
        let size = LibraryPageSizePolicy.followUpSize(
            previousTotalCount: 10,
            newTotalCount: 500,
            hasNext: true
        )
        #expect(size == LibraryPageSizePolicy.maxSize)
    }
}
