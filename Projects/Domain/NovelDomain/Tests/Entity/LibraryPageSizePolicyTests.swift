//
//  LibraryPageSizePolicyTests.swift
//  NovelDomain
//
//  Created by YunhakLee on 8/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

import NovelDomain

@Suite("서재 요청 개수")
struct LibraryPageSizePolicyTests {

    @Suite("다시 들어올 때 보던 만큼 받기")
    struct Refresh {

        @Test("보던 개수만큼 다시 요청한다")
        func requestsLoadedCount() {
            let size = LibraryPageSizePolicy.refreshSize(loadedCount: 47)

            #expect(size == 47)
        }

        @Test(
            "아직 한 페이지를 다 받지 못했으면 한 페이지(15개)를 요청한다",
            arguments: [
                0,   // 아무것도 못 받음
                14   // 한 페이지에서 하나 모자람
            ]
        )
        func requestsOnePageWhenLessThanPage(loadedCount: Int) {
            let size = LibraryPageSizePolicy.refreshSize(loadedCount: loadedCount)

            #expect(size == 15)
        }

        @Test(
            "보던 개수가 100개를 넘으면 100개에서 자른다",
            arguments: [
                100,  // 딱 상한
                101   // 상한에서 하나 넘음
            ]
        )
        func capsAt100(loadedCount: Int) {
            let size = LibraryPageSizePolicy.refreshSize(loadedCount: loadedCount)

            #expect(size == 100)
        }
    }

    @Suite("그사이 늘어난 만큼 더 받기")
    struct FollowUp {

        @Test(
            "비운 사이 늘어난 만큼만 이어서 요청한다",
            arguments: [
                (26, 1),  // 1개 늘어남(이어 받는 가장 작은 경우)
                (27, 2)   // 2개 늘어남
            ]
        )
        func requestsOnlyIncrease(newTotalCount: Int, expected: Int) {
            let size = LibraryPageSizePolicy.followUpSize(previousTotalCount: 25, newTotalCount: newTotalCount, hasNext: true)

            #expect(size == expected)
        }

        @Test(
            "늘지 않았거나 줄었으면 이어서 요청하지 않는다",
            arguments: [
                25,  // 그대로(0개 늘어남)
                22   // 3개 줄어듦
            ]
        )
        func noFollowUpWithoutIncrease(newTotalCount: Int) {
            let size = LibraryPageSizePolicy.followUpSize(previousTotalCount: 25, newTotalCount: newTotalCount, hasNext: true)

            #expect(size == nil)
        }

        @Test("다음 페이지가 없으면 늘었어도 이어서 요청하지 않는다")
        func noFollowUpWithoutNextPage() {
            let size = LibraryPageSizePolicy.followUpSize(previousTotalCount: 25, newTotalCount: 27, hasNext: false)

            #expect(size == nil)
        }

        @Test(
            "늘어난 개수가 100개를 넘으면 100개에서 자른다",
            arguments: [
                110,  // 100개 늘어남(딱 상한)
                111   // 101개 늘어남(상한에서 하나 넘음)
            ]
        )
        func capsAt100(newTotalCount: Int) {
            let size = LibraryPageSizePolicy.followUpSize(previousTotalCount: 10, newTotalCount: newTotalCount, hasNext: true)

            #expect(size == 100)
        }
    }
}
