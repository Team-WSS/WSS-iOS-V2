//
//  RecommendationMapperTests.swift
//  RecommendationData
//
//  Created by Seoyeon Choi on 3/30/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing
@testable import RecommendationData
import RecommendationDomain
import BaseDomain
import BaseData

@Suite("RecommendationMapper")
struct RecommendationMapperTests {

    // MARK: - Helpers

    private func makeTodayDiscoveryNovelResponse(
        novelId: Int = 1,
        title: String = "오늘의 발견 소설",
        novelImage: String = "https://example.com/novel.jpg",
        author: String = "작가A",
        genreName: String = "romance",
        isNovelCompleted: Bool = false,
        keywords: [String] = ["빙의"],
        novelDescription: String = "작품 소개글입니다",
        avatarImage: String? = nil,
        nickname: String? = nil,
        feedContent: String? = "소설 설명입니다"
    ) -> TodayDiscoveryNovelResponse {
        TodayDiscoveryNovelResponse(
            novelId: novelId,
            title: title,
            novelImage: novelImage,
            author: author,
            genreName: genreName,
            isNovelCompleted: isNovelCompleted,
            keywords: keywords,
            novelDescription: novelDescription,
            avatarImage: avatarImage,
            nickname: nickname,
            feedContent: feedContent
        )
    }

    private func makeTrendingFeedResponse(
        feedId: Int = 1,
        feedContent: String = "지금 뜨는 글 내용",
        likeCount: Int = 50,
        commentCount: Int = 10,
        isSpoiler: Bool = false,
        isPublic: Bool = true,
        novelTitle: String = "테스트 작품",
        novelImage: String = "https://example.com/novel.jpg",
        novelGenre: String = "romance"
    ) -> TrendingFeedResponse {
        TrendingFeedResponse(
            feedId: feedId,
            feedContent: feedContent,
            likeCount: likeCount,
            commentCount: commentCount,
            isSpoiler: isSpoiler,
            isPublic: isPublic,
            novelTitle: novelTitle,
            novelImage: novelImage,
            novelGenre: novelGenre
        )
    }

    private func makeInterestFeedResponse(
        novelId: Int = 1,
        novelTitle: String = "관심글 소설",
        novelImage: String = "https://example.com/novel.jpg",
        novelRating: Float = 4.5,
        novelRatingCount: Int = 100,
        nickname: String = "유저닉네임",
        avatarImage: String = "https://example.com/avatar.jpg",
        feedContent: String = "재밌어요"
    ) -> InterestFeedResponse {
        InterestFeedResponse(
            novelId: novelId,
            novelTitle: novelTitle,
            novelImage: novelImage,
            novelRating: novelRating,
            novelRatingCount: novelRatingCount,
            nickname: nickname,
            avatarImage: avatarImage,
            feedContent: feedContent
        )
    }

    private func makePreferenceGenreNovelResponse(
        novelId: Int = 1,
        title: String = "선호 장르 소설",
        author: String = "작가A",
        novelImage: String = "https://example.com/novel.jpg",
        interestCount: Int = 200,
        novelRating: Float = 4.0,
        novelRatingCount: Int = 300
    ) -> PreferenceGenreNovelResponse {
        PreferenceGenreNovelResponse(
            novelId: novelId,
            title: title,
            author: author,
            novelImage: novelImage,
            interestCount: interestCount,
            novelRating: novelRating,
            novelRatingCount: novelRatingCount
        )
    }

    private func makeSosopickNovelResponse(
        novelId: Int = 1,
        novelImage: String = "https://example.com/novel.jpg",
        title: String = "소소픽 소설"
    ) -> SosopickNovelResponse {
        SosopickNovelResponse(
            novelId: novelId,
            novelImage: novelImage,
            title: title
        )
    }

    // MARK: - 오늘의 발견

    // 닉네임·아바타는 유저 한마디 카드에서 함께 채워지거나 함께 null이다 — 한쪽만 온 응답은
    // 서버 이상이므로 작품 소개 카드로 눙치지 않고 실패시킨다(한마디를 조용히 잃지 않기 위해).

    @Test("nickname 없이 avatarImage만 오면 매핑에 실패한다")
    func throwsWhenOnlyAvatarImageIsPresent() {
        let dto = TodayDiscoveryNovelsResponse(
            popularNovels: [
                makeTodayDiscoveryNovelResponse(avatarImage: "https://example.com/avatar.jpg", nickname: nil)
            ]
        )

        #expect(throws: MappingError.self) {
            try RecommendationMapper.todayDiscoveryNovels(from: dto)
        }
    }

    @Test("avatarImage 없이 nickname만 오면 매핑에 실패한다")
    func throwsWhenOnlyNicknameIsPresent() {
        let dto = TodayDiscoveryNovelsResponse(
            popularNovels: [
                makeTodayDiscoveryNovelResponse(avatarImage: nil, nickname: "유저닉네임")
            ]
        )

        #expect(throws: MappingError.self) {
            try RecommendationMapper.todayDiscoveryNovels(from: dto)
        }
    }

    @Test("nickname과 avatarImage가 모두 nil이면 novel 타입으로 매핑된다")
    func mapsToNovelTypeWhenBothNil() throws {
        let dto = TodayDiscoveryNovelsResponse(
            popularNovels: [
                makeTodayDiscoveryNovelResponse(avatarImage: nil, nickname: nil)
            ]
        )

        let result = try RecommendationMapper.todayDiscoveryNovels(from: dto)

        var isMatch = false
        if case .novel = result.first?.content { isMatch = true }
        #expect(isMatch)
    }

    @Test("nickname과 avatarImage가 모두 존재하면 userComment 타입으로 매핑된다")
    func mapsToUserCommentTypeWhenBothPresent() throws {
        let dto = TodayDiscoveryNovelsResponse(
            popularNovels: [
                makeTodayDiscoveryNovelResponse(
                    avatarImage: "https://example.com/avatar.jpg",
                    nickname: "테스트유저"
                )
            ]
        )

        let result = try RecommendationMapper.todayDiscoveryNovels(from: dto)

        guard case .userComment(let user) = result.first?.content else {
            Issue.record("userComment 타입이어야 합니다")
            return
        }
        #expect(user.nickname == "테스트유저")
    }

    @Test("작품 소개 카드의 본문은 novelDescription이 된다")
    func usesNovelDescriptionForNovelType() throws {
        let dto = TodayDiscoveryNovelsResponse(
            popularNovels: [
                makeTodayDiscoveryNovelResponse(
                    novelDescription: "흥미로운 작품 소개",
                    avatarImage: nil,
                    nickname: nil,
                    feedContent: "이 값은 쓰이지 않는다"
                )
            ]
        )

        let result = try RecommendationMapper.todayDiscoveryNovels(from: dto)

        #expect(result.first?.contentDescription == "흥미로운 작품 소개")
    }

    @Test("유저 한마디 카드의 본문은 feedContent가 된다")
    func usesFeedContentForUserCommentType() throws {
        let dto = TodayDiscoveryNovelsResponse(
            popularNovels: [
                makeTodayDiscoveryNovelResponse(
                    novelDescription: "이 값은 쓰이지 않는다",
                    avatarImage: "https://example.com/avatar.jpg",
                    nickname: "테스트유저",
                    feedContent: "강추합니다!"
                )
            ]
        )

        let result = try RecommendationMapper.todayDiscoveryNovels(from: dto)

        #expect(result.first?.contentDescription == "강추합니다!")
    }

    @Test("유저 한마디 카드에 본문이 없으면 매핑에 실패한다")
    func throwsWhenUserCommentHasNoContent() {
        let dto = TodayDiscoveryNovelsResponse(
            popularNovels: [
                makeTodayDiscoveryNovelResponse(
                    avatarImage: "https://example.com/avatar.jpg",
                    nickname: "테스트유저",
                    feedContent: nil
                )
            ]
        )

        // 빈 본문으로 눙치면 내용 없는 말풍선 카드가 홈에 그대로 그려진다 — 서버 계약 위반을
        // 매핑 실패로 드러낸다(Repository가 `.invalidData`로 변환).
        #expect(throws: MappingError.self) {
            try RecommendationMapper.todayDiscoveryNovels(from: dto)
        }
    }

    @Test("작품 소개 카드는 feedContent가 채워져 와도 작품 소개로 남는다")
    func staysNovelTypeEvenWhenFeedContentIsPresent() throws {
        // 서버가 소개 카드의 feedContent에도 같은 소개글을 넣어 보내는 경우가 있다(#179 실측).
        // 형태 판정에 feedContent를 끌어들이면 이런 카드가 유저 한마디로 뒤집힌다.
        let dto = TodayDiscoveryNovelsResponse(
            popularNovels: [
                makeTodayDiscoveryNovelResponse(
                    novelDescription: "흥미로운 작품 소개",
                    avatarImage: nil,
                    nickname: nil,
                    feedContent: "흥미로운 작품 소개"
                )
            ]
        )

        let result = try RecommendationMapper.todayDiscoveryNovels(from: dto)

        var isMatch = false
        if case .novel = result.first?.content { isMatch = true }
        #expect(isMatch)
        #expect(result.first?.contentDescription == "흥미로운 작품 소개")
    }

    @Test("작가·키워드와 영문 장르가 도메인 값으로 매핑된다")
    func mapsNovelMetadata() throws {
        let dto = TodayDiscoveryNovelsResponse(
            popularNovels: [
                makeTodayDiscoveryNovelResponse(
                    author: "캐슈",
                    genreName: "BL",
                    keywords: ["사랑꾼", "짝사랑"]
                )
            ]
        )

        let result = try RecommendationMapper.todayDiscoveryNovels(from: dto)

        #expect(result.first?.novelAuthor == "캐슈")
        #expect(result.first?.novelGenre == .BL)
        #expect(result.first?.keywords == ["사랑꾼", "짝사랑"])
    }

    @Test("isNovelCompleted가 true면 완결작으로 매핑된다")
    func mapsCompletedPublicationStatus() throws {
        let dto = TodayDiscoveryNovelsResponse(
            popularNovels: [makeTodayDiscoveryNovelResponse(isNovelCompleted: true)]
        )

        let result = try RecommendationMapper.todayDiscoveryNovels(from: dto)

        #expect(result.first?.publicationStatus == .completed)
    }

    @Test("isNovelCompleted가 false면 연재작으로 매핑된다")
    func mapsOnGoingPublicationStatus() throws {
        let dto = TodayDiscoveryNovelsResponse(
            popularNovels: [makeTodayDiscoveryNovelResponse(isNovelCompleted: false)]
        )

        let result = try RecommendationMapper.todayDiscoveryNovels(from: dto)

        #expect(result.first?.publicationStatus == .onGoing)
    }

    @Test("알 수 없는 장르 문자열이면 매핑에 실패한다")
    func throwsWhenGenreIsUnknown() {
        let dto = TodayDiscoveryNovelsResponse(
            popularNovels: [makeTodayDiscoveryNovelResponse(genreName: "새로운장르")]
        )

        #expect(throws: MappingError.invalidConversion(type: "NovelGenre", value: "새로운장르")) {
            try RecommendationMapper.todayDiscoveryNovels(from: dto)
        }
    }

    @Test("여러 TodayDiscovery를 배열로 변환한다")
    func mapsMultipleTodayDiscoveries() throws {
        let dto = TodayDiscoveryNovelsResponse(
            popularNovels: [
                makeTodayDiscoveryNovelResponse(novelId: 1, title: "소설1"),
                makeTodayDiscoveryNovelResponse(novelId: 2, title: "소설2"),
                makeTodayDiscoveryNovelResponse(novelId: 3, title: "소설3")
            ]
        )

        let result = try RecommendationMapper.todayDiscoveryNovels(from: dto)

        #expect(result.count == 3)
        #expect(result[0].novelTitle == "소설1")
        #expect(result[2].novelTitle == "소설3")
    }

    // MARK: - 지금 뜨는 글

    @Test("DTO에서 TrendingFeed로 정상 변환된다")
    func mapsTrendingFeedResponseToDomain() throws {
        let dto = TrendingFeedsResponse(
            popularFeeds: [
                makeTrendingFeedResponse(feedId: 42, feedContent: "인기 피드", likeCount: 100, commentCount: 20)
            ]
        )

        let result = try RecommendationMapper.trendingFeeds(from: dto)

        #expect(result.first?.feedID == FeedID(42))
        #expect(result.first?.description == "인기 피드")
        #expect(result.first?.likeCount == 100)
        #expect(result.first?.commentCount == 20)
    }

    @Test("글이 달린 작품의 제목과 영문 장르가 함께 매핑된다")
    func mapsTrendingFeedNovelInformation() throws {
        let dto = TrendingFeedsResponse(
            popularFeeds: [
                makeTrendingFeedResponse(novelTitle: "우아한 오브리", novelGenre: "romanceFantasy")
            ]
        )

        let result = try RecommendationMapper.trendingFeeds(from: dto)

        #expect(result.first?.novelTitle == "우아한 오브리")
        #expect(result.first?.novelGenre == .romanceFantasy)
    }

    @Test("isSpoiler 값이 그대로 매핑된다")
    func mapsSpoilerFlagCorrectly() throws {
        let dto = TrendingFeedsResponse(
            popularFeeds: [
                makeTrendingFeedResponse(isSpoiler: true)
            ]
        )

        let result = try RecommendationMapper.trendingFeeds(from: dto)

        #expect(result.first?.isSpoiler == true)
    }

    @Test("여러 TrendingFeed를 배열로 변환한다")
    func mapsMultipleTrendingFeeds() throws {
        let dto = TrendingFeedsResponse(
            popularFeeds: [
                makeTrendingFeedResponse(feedId: 1),
                makeTrendingFeedResponse(feedId: 2)
            ]
        )

        let result = try RecommendationMapper.trendingFeeds(from: dto)

        #expect(result.count == 2)
    }

    // MARK: - 관심글

    @Test("message가 NO_INTEREST_NOVELS이면 noInterestSettings를 반환한다")
    func mapsToNoInterestSettingsWhenMessageIsNoInterestNovels() {
        let dto = InterestFeedsResponse(
            recommendFeeds: [],
            message: "NO_INTEREST_NOVELS"
        )

        let result = RecommendationMapper.interestFeeds(from: dto)

        var isMatch = false
        if case .noInterestSettings = result { isMatch = true }
        #expect(isMatch)
    }

    @Test("message가 NO_ASSOCIATED_FEEDS이면 noAssociatedFeeds를 반환한다")
    func mapsToNoAssociatedFeedsWhenMessageIsNoAssociatedFeeds() {
        let dto = InterestFeedsResponse(
            recommendFeeds: [],
            message: "NO_ASSOCIATED_FEEDS"
        )

        let result = RecommendationMapper.interestFeeds(from: dto)

        var isMatch = false
        if case .noAssociatedFeeds = result { isMatch = true }
        #expect(isMatch)
    }

    @Test("message가 다른 값이면 feeds 상태를 반환한다")
    func mapsToFeedsStateForOtherMessage() {
        let dto = InterestFeedsResponse(
            recommendFeeds: [makeInterestFeedResponse()],
            message: "SUCCESS"
        )

        let result = RecommendationMapper.interestFeeds(from: dto)

        guard case .feeds(let feeds) = result else {
            Issue.record("feeds 상태여야 합니다")
            return
        }
        #expect(feeds.count == 1)
    }

    @Test("피드 데이터가 InterestFeed로 정상 변환된다")
    func mapsInterestFeedResponseToDomain() {
        let dto = InterestFeedsResponse(
            recommendFeeds: [
                makeInterestFeedResponse(
                    novelId: 5,
                    novelTitle: "관심 소설",
                    novelRating: 3.5,
                    novelRatingCount: 50,
                    nickname: "피드작성자"
                )
            ],
            message: "SUCCESS"
        )

        let result = RecommendationMapper.interestFeeds(from: dto)

        guard case .feeds(let feeds) = result, let feed = feeds.first else {
            Issue.record("feeds 상태여야 합니다")
            return
        }
        #expect(feed.novelID == NovelID(5))
        #expect(feed.novelTitle == "관심 소설")
        #expect(feed.novelRating == 3.5)
        #expect(feed.novelRatingCount == 50)
        #expect(feed.user.nickname == "피드작성자")
    }

    // MARK: - 선호 장르 기반 추천 소설

    @Test("tasteNovels가 비어있으면 noGenreSettings를 반환한다")
    func mapsToNoGenreSettingsWhenTasteNovelsIsEmpty() {
        let dto = PreferenceGenreNovelsResponse(tasteNovels: [])

        let result = RecommendationMapper.preferenceGenreNovels(from: dto)

        var isMatch = false
        if case .noGenreSettings = result { isMatch = true }
        #expect(isMatch)
    }

    @Test("tasteNovels가 있으면 novels 상태를 반환한다")
    func mapsToNovelsStateWhenTasteNovelsIsNotEmpty() {
        let dto = PreferenceGenreNovelsResponse(
            tasteNovels: [makePreferenceGenreNovelResponse()]
        )

        let result = RecommendationMapper.preferenceGenreNovels(from: dto)

        guard case .novels(let novels) = result else {
            Issue.record("novels 상태여야 합니다")
            return
        }
        #expect(novels.count == 1)
    }

    @Test("쉼표로 구분된 author 문자열이 배열로 변환된다")
    func splitsAuthorStringByComma() {
        let dto = PreferenceGenreNovelsResponse(
            tasteNovels: [
                makePreferenceGenreNovelResponse(author: "작가A,작가B,작가C")
            ]
        )

        let result = RecommendationMapper.preferenceGenreNovels(from: dto)

        guard case .novels(let novels) = result else {
            Issue.record("novels 상태여야 합니다")
            return
        }
        #expect(novels.first?.novelAuthors == ["작가A", "작가B", "작가C"])
    }

    @Test("저자가 1명이면 단일 원소 배열로 변환된다")
    func mapsSingleAuthorToSingleElementArray() {
        let dto = PreferenceGenreNovelsResponse(
            tasteNovels: [
                makePreferenceGenreNovelResponse(author: "단독작가")
            ]
        )

        let result = RecommendationMapper.preferenceGenreNovels(from: dto)

        guard case .novels(let novels) = result else {
            Issue.record("novels 상태여야 합니다")
            return
        }
        #expect(novels.first?.novelAuthors == ["단독작가"])
    }

    @Test("DTO의 novelRating과 novelRatingCount가 정상 매핑된다")
    func mapsRatingFieldsCorrectly() {
        let dto = PreferenceGenreNovelsResponse(
            tasteNovels: [
                makePreferenceGenreNovelResponse(
                    interestCount: 123,
                    novelRating: 4.5,
                    novelRatingCount: 999
                )
            ]
        )

        let result = RecommendationMapper.preferenceGenreNovels(from: dto)

        guard case .novels(let novels) = result, let novel = novels.first else {
            Issue.record("novels 상태여야 합니다")
            return
        }
        #expect(novel.rating == 4.5)
        #expect(novel.ratingCount == 999)
        #expect(novel.interestCount == 123)
    }

    // MARK: - 소소픽

    @Test("DTO에서 SosoPick으로 정상 변환된다")
    func mapsSosoPickResponseToDomain() {
        let dto = SosopickNovelsResponse(
            sosoPicks: [makeSosopickNovelResponse(novelId: 7, title: "소소픽 소설")]
        )

        let result = RecommendationMapper.sosopickNovels(from: dto)

        #expect(result.first?.novelID == NovelID(7))
        #expect(result.first?.novelTitle == "소소픽 소설")
    }

    @Test("여러 SosoPick을 배열로 변환한다")
    func mapsMultipleSosoPicks() {
        let dto = SosopickNovelsResponse(
            sosoPicks: [
                makeSosopickNovelResponse(novelId: 1),
                makeSosopickNovelResponse(novelId: 2),
                makeSosopickNovelResponse(novelId: 3)
            ]
        )

        let result = RecommendationMapper.sosopickNovels(from: dto)

        #expect(result.count == 3)
    }

    @Test("빈 sosoPicks는 빈 배열을 반환한다")
    func returnsEmptyArrayWhenSosoPicksIsEmpty() {
        let dto = SosopickNovelsResponse(sosoPicks: [])

        let result = RecommendationMapper.sosopickNovels(from: dto)

        #expect(result.isEmpty)
    }
}
