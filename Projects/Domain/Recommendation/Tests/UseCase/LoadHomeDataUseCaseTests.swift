//
//  LoadHomeDataUseCaseTests.swift
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
struct LoadHomeDataUseCaseTests {
    
    @Test("네 가지 API가 모두 호출된다")
    func callsAllFourApis() async {
        let mock = MockRecommendationRepository()
        mock.fetchTodayDiscoveriesResult = .success([])
        mock.fetchTrendingFeedsResult = .success([])
        mock.fetchInterestFeedsResult = .success(.feeds([]))
        mock.fetchRecommendedNovelsResult = .success(.novels([]))
        
        let usecase = DefaultLoadDataUseCase(repository: mock)
        _ = try? await usecase.execute()
        
        #expect(mock.fetchTodayDiscoveriesCallCount == 1)
        #expect(mock.fetchTrendingFeedsCallCount == 1)
        #expect(mock.fetchInterestFeedsCallCount == 1)
        #expect(mock.fetchRecommendedNovelsCallCount == 1)
    }
    
    @Test("모든 데이터를 성공적으로 불러온다")
    func loadsAllDataSuccessfully() async throws {
        let mock = MockRecommendationRepository()
        mock.fetchTodayDiscoveriesResult = .success([makeTodayDiscovery()])
        mock.fetchTrendingFeedsResult = .success([makeTrendingFeed()])
        mock.fetchInterestFeedsResult = .success(.feeds([]))
        mock.fetchRecommendedNovelsResult = .success(.novels([]))
        
        let usecase = DefaultLoadDataUseCase(repository: mock)
        let homeData = try await usecase.execute()
        
        #expect(homeData.todayDiscoveries.count == 1)
        #expect(homeData.trendingFeeds.count == 1)
    }
    
    @Test("todayDiscoveries 실패 시 전체를 실패로 반환한다")
    func throwsWhenTodayDiscoveriesFails() async {
        let mock = MockRecommendationRepository()
        mock.fetchTodayDiscoveriesResult = .failure(MockError.networkError)
        
        let usecase = DefaultLoadDataUseCase(repository: mock)
        
        await #expect(throws: MockError.networkError) {
            try await usecase.execute()
        }
    }
    
    @Test("특정 API 실패 시 전체를 실패로 반환한다")
    func throwsWhenAnyApiFails() async {
        let mock = MockRecommendationRepository()
        mock.fetchTodayDiscoveriesResult = .success([makeTodayDiscovery()])
        mock.fetchTrendingFeedsResult = .failure(MockError.networkError)
        mock.fetchInterestFeedsResult = .success(.noInterestSettings)
        mock.fetchRecommendedNovelsResult = .success(.noGenreSettings)
        
        let usecase = DefaultLoadDataUseCase(repository: mock)
        
        await #expect(throws: MockError.networkError) {
            try await usecase.execute()
        }
    }
}

extension LoadHomeDataUseCaseTests {
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
