//
//  NovelTests.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import NovelDomain
import NovelDomainTesting
import BaseDomain

@Suite
struct NovelTests {

    // MARK: - markAsInterested

    @Test("관심 없는 작품을 관심 작품으로 등록하면 isInterested가 true가 되고 관심 수가 증가한다")
    func markAsInterestedFromFalse() {
        var novel = makeNovel(isInterested: false, interestCount: 10)

        novel.markAsInterested()

        #expect(novel.isInterested == true)
        #expect(novel.interestCount == 11)
    }

    @Test("이미 관심 등록된 작품에 markAsInterested를 호출하면 상태가 변하지 않는다")
    func markAsInterestedWhenAlreadyInterested() {
        var novel = makeNovel(isInterested: true, interestCount: 10)

        novel.markAsInterested()

        #expect(novel.isInterested == true)
        #expect(novel.interestCount == 10)
    }

    @Test("isInterested가 nil인 작품에 markAsInterested를 호출하면 상태가 변하지 않는다")
    func markAsInterestedWhenNil() {
        var novel = makeNovel(isInterested: nil, interestCount: 10)

        novel.markAsInterested()

        #expect(novel.isInterested == nil)
        #expect(novel.interestCount == 10)
    }

    // MARK: - unmarkAsInterested

    @Test("관심 등록된 작품의 관심을 해제하면 isInterested가 false가 되고 관심 수가 감소한다")
    func unmarkAsInterestedFromTrue() {
        var novel = makeNovel(isInterested: true, interestCount: 10)

        novel.unmarkAsInterested()

        #expect(novel.isInterested == false)
        #expect(novel.interestCount == 9)
    }

    @Test("관심 없는 작품에 unmarkAsInterested를 호출하면 상태가 변하지 않는다")
    func unmarkAsInterestedWhenAlreadyFalse() {
        var novel = makeNovel(isInterested: false, interestCount: 10)

        novel.unmarkAsInterested()

        #expect(novel.isInterested == false)
        #expect(novel.interestCount == 10)
    }

    @Test("관심 수가 0일 때 unmarkAsInterested를 호출하면 관심 수가 0 이하로 내려가지 않는다")
    func unmarkAsInterestedDoesNotGoBelowZero() {
        var novel = makeNovel(isInterested: true, interestCount: 0)

        novel.unmarkAsInterested()

        #expect(novel.isInterested == false)
        #expect(novel.interestCount == 0)
    }

    // MARK: - toggleInterest

    @Test("관심 등록된 작품을 토글하면 관심이 해제된다")
    func toggleInterestFromTrue() {
        var novel = makeNovel(isInterested: true, interestCount: 10)

        novel.toggleInterest()

        #expect(novel.isInterested == false)
        #expect(novel.interestCount == 9)
    }

    @Test("관심 없는 작품을 토글하면 관심이 등록된다")
    func toggleInterestFromFalse() {
        var novel = makeNovel(isInterested: false, interestCount: 10)

        novel.toggleInterest()

        #expect(novel.isInterested == true)
        #expect(novel.interestCount == 11)
    }
}

extension NovelTests {
    private func makeNovel(
        isInterested: Bool? = nil,
        interestCount: Int = 0
    ) -> Novel {
        Novel(
            id: NovelID(1),
            thumbnailImage: nil,
            title: "전지적 독자 시점",
            author: ["싱숑"],
            interestCount: interestCount,
            rating: 4.5,
            ratingCount: 50,
            isInterested: isInterested
        )
    }
}
