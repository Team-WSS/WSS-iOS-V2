//
//  LoadHomeDataUsecaseTests.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import RecommendationDomain
@testable import BaseDomain
@testable import RecommendationDomainTesting

@Suite
struct LoadHomeDataUsecaseTests {

    @Test func `모든 데이터를 성공적으로 불러온다.`() async throws {
        let mock = MockRecommendationRepository()
        mock.fetchTodayDiscoveriesResult = .success([makeTodayDiscovery()])
        mock.fetchTrendingFeedsResult = .success([makeTrendingFeed()])
        mock.fetchInterestFeedsResult = .success(.feeds([]))
        mock.fetchRecommendedNovelsResult = .success(.novels([]))

        let usecase = DefaultLoadDataUsecase(repository: mock)
        let homeData = await usecase.execute()

        let discoveries = try homeData.todayDiscoveries.get()
        let feeds = try homeData.trendingFeeds.get()
        let interestState = try homeData.interestFeedState.get()
        let novelState = try homeData.recommendedNovelState.get()

        #expect(discoveries.count == 1)
        #expect(feeds.count == 1)

        var isFeeds = false
        if case .feeds = interestState { isFeeds = true }
        #expect(isFeeds)

        var isNovels = false
        if case .novels = novelState { isNovels = true }
        #expect(isNovels)
    }

    @Test func `todayDiscoveries 실패 시 해당 필드만 failure로 반환한다.`() async {
        let mock = MockRecommendationRepository()
        mock.fetchTodayDiscoveriesResult = .failure(MockError.networkError)

        let usecase = DefaultLoadDataUsecase(repository: mock)
        let homeData = await usecase.execute()

        #expect(throws: MockError.networkError) {
            try homeData.todayDiscoveries.get()
        }
    }

    @Test func `특정 API 실패 시 나머지 필드는 성공으로 반환한다.`() async throws {
        let mock = MockRecommendationRepository()
        mock.fetchTodayDiscoveriesResult = .failure(MockError.networkError)
        mock.fetchTrendingFeedsResult = .success([makeTrendingFeed()])
        mock.fetchInterestFeedsResult = .success(.noInterestSettings)
        mock.fetchRecommendedNovelsResult = .success(.noGenreSettings)

        let usecase = DefaultLoadDataUsecase(repository: mock)
        let homeData = await usecase.execute()

        // todayDiscoveries만 실패
        #expect(throws: MockError.networkError) {
            try homeData.todayDiscoveries.get()
        }

        // 나머지 필드는 성공
        let feeds = try homeData.trendingFeeds.get()
        #expect(feeds.count == 1)

        let interestState = try homeData.interestFeedState.get()
        var isNoInterest = false
        if case .noInterestSettings = interestState { isNoInterest = true }
        #expect(isNoInterest)

        let novelState = try homeData.recommendedNovelState.get()
        var isNoGenre = false
        if case .noGenreSettings = novelState { isNoGenre = true }
        #expect(isNoGenre)
    }

    @Test func `네 가지 API가 모두 동시에 호출된다.`() async {
        let mock = MockRecommendationRepository()

        let usecase = DefaultLoadDataUsecase(repository: mock)
        _ = await usecase.execute()

        #expect(mock.fetchTodayDiscoveriesCallCount == 1)
        #expect(mock.fetchTrendingFeedsCallCount == 1)
        #expect(mock.fetchInterestFeedsCallCount == 1)
        #expect(mock.fetchRecommendedNovelsCallCount == 1)
    }
}

extension LoadHomeDataUsecaseTests {
    private func makeTodayDiscovery() -> TodayDiscovery {
        TodayDiscovery(
            novelID: NovelID(1),
            novelTitle: "오늘의 발견",
            novelThumbnailImage: nil,
            content: .novel(description: "소설 설명")
        )
    }

    private func makeTrendingFeed() -> TrendingFeed {
        TrendingFeed(
            feedID: FeedID(1),
            description: "뜨는 글 내용",
            likeCount: 10,
            commentCount: 3
        )
    }
}
