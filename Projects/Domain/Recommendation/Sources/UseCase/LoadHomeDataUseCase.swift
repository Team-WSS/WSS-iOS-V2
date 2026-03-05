//
//  LoadHomeDataUseCase.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol LoadHomeDataUseCase {
    func execute() async throws -> HomeData
}

public final class DefaultLoadDataUseCase: LoadHomeDataUseCase {
    
    private let recommendationRepository: RecommendationRepository
    
    public init(repository: RecommendationRepository) {
        self.recommendationRepository = repository
    }
    
    public func execute() async throws -> HomeData {
        async let todayDiscoveries = recommendationRepository.fetchTodayDiscoveries()
        async let trendingFeeds = recommendationRepository.fetchTrendingFeeds()
        async let interestFeedState = recommendationRepository.fetchInterestFeeds()
        async let recommendedNovelState = recommendationRepository.fetchRecommendedNovels()
        
        return await HomeData(
            todayDiscoveries: try todayDiscoveries,
            trendingFeeds: try trendingFeeds,
            interestFeedState: try interestFeedState,
            recommendedNovelState: try recommendedNovelState
        )
    }
}
