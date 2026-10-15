//
//  NovelTests.swift
//  BaseDomain
//
//  Created by Seoyeon Choi on 2/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

import BaseDomain

@Suite("작품 관심 등록")
struct NovelTests {

    // MARK: - 등록

    @Test("관심 작품으로 등록하면 관심 수가 하나 늘어난다")
    func markingAddsInterest() {
        var novel = makeNovel(isInterested: false, interestCount: 10)

        novel.markAsInterested()

        #expect(novel.isInterested == true)
        #expect(novel.interestCount == 11)
    }

    @Test("이미 관심 작품이면 다시 등록해도 그대로다")
    func markingAgainChangesNothing() {
        var novel = makeNovel(isInterested: true, interestCount: 10)

        novel.markAsInterested()

        #expect(novel.isInterested == true)
        #expect(novel.interestCount == 10)
    }

    @Test("관심 여부를 모르는 작품은 관심 작품으로 등록하지 않는다")
    func markingUnknownChangesNothing() {
        var novel = makeNovel(isInterested: nil, interestCount: 10)

        novel.markAsInterested()

        #expect(novel.isInterested == nil)
        #expect(novel.interestCount == 10)
    }

    // MARK: - 해제

    @Test("관심을 해제하면 관심 수가 하나 줄어든다")
    func unmarkingRemovesInterest() {
        var novel = makeNovel(isInterested: true, interestCount: 10)

        novel.unmarkAsInterested()

        #expect(novel.isInterested == false)
        #expect(novel.interestCount == 9)
    }

    @Test("관심 작품이 아니면 해제해도 그대로다")
    func unmarkingNonInterestChangesNothing() {
        var novel = makeNovel(isInterested: false, interestCount: 10)

        novel.unmarkAsInterested()

        #expect(novel.isInterested == false)
        #expect(novel.interestCount == 10)
    }

    @Test("관심 수가 0이면 해제해도 0 아래로 내려가지 않는다")
    func unmarkingNeverGoesBelowZero() {
        var novel = makeNovel(isInterested: true, interestCount: 0)

        novel.unmarkAsInterested()

        #expect(novel.isInterested == false)
        #expect(novel.interestCount == 0)
    }

    // MARK: - 전환

    @Test("관심 작품에서 관심을 전환하면 해제된다")
    func togglingInterestRemovesIt() {
        var novel = makeNovel(isInterested: true, interestCount: 10)

        novel.toggleInterest()

        #expect(novel.isInterested == false)
        #expect(novel.interestCount == 9)
    }

    @Test("관심 작품이 아닐 때 관심을 전환하면 등록된다")
    func togglingNonInterestAddsIt() {
        var novel = makeNovel(isInterested: false, interestCount: 10)

        novel.toggleInterest()

        #expect(novel.isInterested == true)
        #expect(novel.interestCount == 11)
    }

    // MARK: - Helpers

    private func makeNovel(isInterested: Bool?, interestCount: Int) -> Novel {
        Novel(
            id: NovelID(1),
            thumbnailImage: nil,
            title: "작품",
            authors: ["작가"],
            genres: [],
            interestCount: interestCount,
            rating: 4.5,
            ratingCount: 10,
            isInterested: isInterested
        )
    }
}
