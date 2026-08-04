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

    // MARK: - 작품 정보

    @Test("작품의 작가·장르·연재상태를 함께 담는다")
    func carriesNovelMetadata() {
        let discovery = makeTodayDiscovery(
            novelAuthor: "캐슈",
            novelGenre: .BL,
            publicationStatus: .completed
        )

        #expect(discovery.novelAuthor == "캐슈")
        #expect(discovery.novelGenre == .BL)
        #expect(discovery.publicationStatus == .completed)
    }

    @Test("작품 키워드를 순서 그대로 담는다")
    func carriesKeywordsInOrder() {
        let discovery = makeTodayDiscovery(keywords: ["사랑꾼", "짝사랑"])

        #expect(discovery.keywords == ["사랑꾼", "짝사랑"])
    }

    @Test("키워드가 없는 작품은 빈 배열을 담는다")
    func carriesEmptyKeywordsWhenNone() {
        let discovery = makeTodayDiscovery(keywords: [])

        #expect(discovery.keywords.isEmpty)
    }
}

extension TodayDiscoveryTests {

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
        novelAuthor: String = "테스트작가",
        novelGenre: NovelGenre = .romance,
        publicationStatus: NovelPublicationStatus = .onGoing,
        keywords: [String] = ["빙의"],
        content: TodayDiscovery.Content = .novel,
        contentDescription: String = "소설 설명"
    ) -> TodayDiscovery {
        TodayDiscovery(
            novelID: novelID,
            novelTitle: novelTitle,
            novelThumbnailImage: novelThumbnailImage,
            novelAuthor: novelAuthor,
            novelGenre: novelGenre,
            publicationStatus: publicationStatus,
            keywords: keywords,
            content: content,
            contentDescription: contentDescription
        )
    }
}
