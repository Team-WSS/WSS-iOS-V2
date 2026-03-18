//
//  LoadHomeDataUseCase.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol LoadHomeDataUseCase {
    func execute() async throws(RepositoryError) -> HomeData
}

public final class DefaultLoadDataUseCase: LoadHomeDataUseCase {
    
    private let recommendationRepository: RecommendationRepository
    
    public init(repository: RecommendationRepository) {
        self.recommendationRepository = repository
    }
    
    public func execute() async throws(RepositoryError) -> HomeData {
        let todayDiscoveries = try await recommendationRepository.fetchTodayDiscoveries()
        let trendingFeeds = try await recommendationRepository.fetchTrendingFeeds()
        let interestFeedState = try await recommendationRepository.fetchInterestFeeds()
        let recommendedNovelState = try await recommendationRepository.fetchRecommendedNovels()
        
        return HomeData(
            todayDiscoveries: todayDiscoveries,
            trendingFeeds: trendingFeeds,
            interestFeedState: interestFeedState,
            recommendedNovelState: recommendedNovelState
        )
    }
}
