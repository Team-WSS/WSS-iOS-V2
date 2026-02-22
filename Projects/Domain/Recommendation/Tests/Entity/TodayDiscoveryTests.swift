//
//  TodayDiscoveryTests.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
import Foundation
@testable import RecommendationDomain
@testable import BaseDomain

@Suite
struct TodayDiscoveryTests {

    // MARK: - Helpers

    private func makeAuthor() -> Author {
        Author(
            userId: UserID(1),
            nickname: "테스트유저",
            profileImage: ImageWrapper(identifier: "profile")
        )
    }

    private func makeTodayDiscovery(
        novelID: NovelID = NovelID(1),
        novelTitle: String = "오늘의 발견 소설",
        novelThumbnailImage: URL? = nil,
        content: TodayDiscovery.Content = .novel(description: "소설 설명")
    ) -> TodayDiscovery {
        TodayDiscovery(
            novelID: novelID,
            novelTitle: novelTitle,
            novelThumbnailImage: novelThumbnailImage,
            content: content
        )
    }

    // MARK: - Content 타입

    @Test("novel 타입으로 오늘의 발견을 생성할 수 있다")
    func canCreateTodayDiscoveryWithNovelType() {
        let discovery = makeTodayDiscovery(content: .novel(description: "흥미로운 소설입니다"))

        var isMatch = false
        if case .novel = discovery.content { isMatch = true }

        #expect(isMatch)
    }

    @Test("userComment 타입으로 오늘의 발견을 생성할 수 있다")
    func canCreateTodayDiscoveryWithUserCommentType() {
        let discovery = makeTodayDiscovery(
            content: .userComment(user: makeAuthor(), comment: "강추합니다!")
        )

        var isMatch = false
        if case .userComment = discovery.content { isMatch = true }

        #expect(isMatch)
    }

    @Test("novel 타입에서 설명 텍스트를 가져올 수 있다")
    func canGetDescriptionFromNovelType() {
        let description = "이 소설은 매우 흥미롭습니다"
        let discovery = makeTodayDiscovery(content: .novel(description: description))

        guard case .novel(let result) = discovery.content else {
            Issue.record("novel 타입이어야 합니다")
            return
        }

        #expect(result == description)
    }

    @Test("userComment 타입에서 유저 정보와 한마디를 가져올 수 있다")
    func canGetUserInfoAndCommentFromUserCommentType() {
        let author = makeAuthor()
        let comment = "이 작품은 정말 최고입니다"
        let discovery = makeTodayDiscovery(
            content: .userComment(user: author, comment: comment)
        )

        guard case .userComment(let user, let result) = discovery.content else {
            Issue.record("userComment 타입이어야 합니다")
            return
        }

        #expect(user.nickname == author.nickname)
        #expect(result == comment)
    }
}
