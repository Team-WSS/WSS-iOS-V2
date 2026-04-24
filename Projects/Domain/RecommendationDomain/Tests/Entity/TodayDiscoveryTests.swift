//
//  TodayDiscoveryTests.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

@testable import RecommendationDomain
import RecommendationDomainTesting
import BaseDomain

@Suite
struct TodayDiscoveryTests {

    // MARK: - Helpers

    private func makeAuthor() -> Author {
        Author(
            userId: UserID(1),
            nickname: "테스트유저",
            profileImage: URL(string: "")
        )
    }

    private func makeTodayDiscovery(
        novelID: NovelID = NovelID(1),
        novelTitle: String = "오늘의 발견 소설",
        novelThumbnailImage: URL? = nil,
        content: TodayDiscovery.Content = .novel,
        contentDescription: String = "소설 설명"
    ) -> TodayDiscovery {
        TodayDiscovery(
            novelID: novelID,
            novelTitle: novelTitle,
            novelThumbnailImage: novelThumbnailImage,
            content: content,
            contentDescription: contentDescription
        )
    }

    // MARK: - Content 타입

    @Test("novel 타입으로 오늘의 발견을 생성할 수 있다")
    func canCreateTodayDiscoveryWithNovelType() {
        let discovery = makeTodayDiscovery(content: .novel)

        var isMatch = false
        if case .novel = discovery.content { isMatch = true }

        #expect(isMatch)
    }

    @Test("userComment 타입으로 오늘의 발견을 생성할 수 있다")
    func canCreateTodayDiscoveryWithUserCommentType() {
        let discovery = makeTodayDiscovery(
            content: .userComment(user: makeAuthor())
        )

        var isMatch = false
        if case .userComment = discovery.content { isMatch = true }

        #expect(isMatch)
    }

    @Test("userComment 타입에서 유저 정보를 가져올 수 있다")
    func canGetUserInfoFromUserCommentType() {
        let author = makeAuthor()
        let discovery = makeTodayDiscovery(
            content: .userComment(user: author)
        )

        guard case .userComment(let user) = discovery.content else {
            Issue.record("userComment 타입이어야 합니다")
            return
        }

        #expect(user.nickname == author.nickname)
    }

    @Test("contentDescription에 본문 텍스트가 저장된다")
    func contentDescriptionStoresBodyText() {
        let discovery = makeTodayDiscovery(contentDescription: "본문 내용")

        #expect(discovery.contentDescription == "본문 내용")
    }

    // MARK: - title / description

    @Test("novel 타입의 title은 작품 소개이다")
    func novelTypeTitleIsNovelIntroduction() {
        let discovery = makeTodayDiscovery(content: .novel)

        #expect(discovery.title == "작품 소개")
    }

    @Test("userComment 타입의 title은 닉네임의 한마디이다")
    func userCommentTypeTitleIncludesNickname() {
        let discovery = makeTodayDiscovery(
            content: .userComment(user: makeAuthor())
        )

        #expect(discovery.title == "테스트유저의 한마디")
    }

    @Test("novel 타입의 description은 작품 소개글이다")
    func novelTypeDescriptionIsNovelDescription() {
        let discovery = makeTodayDiscovery(
            content: .novel,
            contentDescription: "흥미로운 소설입니다"
        )

        #expect(discovery.description == "흥미로운 소설입니다")
    }

    @Test("userComment 타입의 description은 유저의 피드 내용이다")
    func userCommentTypeDescriptionIsUserComment() {
        let discovery = makeTodayDiscovery(
            content: .userComment(user: makeAuthor()),
            contentDescription: "강추합니다!"
        )

        #expect(discovery.description == "강추합니다!")
    }
}
