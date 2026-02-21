//
//  LoadHomeDataUsecase.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol LoadHomeDataUsecase {
    func execute() async -> HomeData
}

public final class DefaultLoadDataUsecase: LoadHomeDataUsecase {
    
    private let recommendationRepository: RecommendationRepository
    
    public init(repository: RecommendationRepository) {
        self.recommendationRepository = repository
    }
    
    public func execute() async -> HomeData {
        async let todayDiscoveries: Result<[TodayDiscovery], Error> = {
            do { return .success(try await recommendationRepository.fetchTodayDiscoveries()) }
            catch { return .failure(error) }
        }()
        async let trendingFeeds: Result<[TrendingFeed], Error> = {
            do { return .success(try await recommendationRepository.fetchTrendingFeeds()) }
            catch { return .failure(error) }
        }()
        async let interestFeeds: Result<InterestFeedState, Error> = {
            do { return .success(try await recommendationRepository.fetchInterestFeeds()) }
            catch { return .failure(error) }
        }()
        async let recommendedNovels: Result<RecommendedNovelState, Error> = {
            do { return .success(try await recommendationRepository.fetchRecommendedNovels()) }
            catch { return .failure(error) }
        }()
        
        return await HomeData(
            todayDiscoveries: todayDiscoveries,
            trendingFeeds: trendingFeeds,
            interestFeedState: interestFeeds,
            recommendedNovelState: recommendedNovels
        )
    }
}
