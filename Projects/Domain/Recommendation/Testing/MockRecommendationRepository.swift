//
//  MockRecommendationRepository.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import RecommendationDomain
import BaseDomain

public final class MockRecommendationRepository: RecommendationRepository {

    public var fetchTodayDiscoveriesCallCount = 0
    public var fetchTrendingFeedsCallCount = 0
    public var fetchInterestFeedsCallCount = 0
    public var fetchRecommendedNovelsCallCount = 0
    public var fetchSosoPickCallCount = 0

    public var fetchTodayDiscoveriesResult: Result<[TodayDiscovery], RepositoryError> = .success([])
    public var fetchTrendingFeedsResult: Result<[TrendingFeed], RepositoryError> = .success([])
    public var fetchInterestFeedsResult: Result<InterestFeedState, RepositoryError> = .success(.noInterestSettings)
    public var fetchRecommendedNovelsResult: Result<RecommendedNovelState, RepositoryError> = .success(.noGenreSettings)
    public var fetchSosoPickResult: Result<[SosoPick], RepositoryError> = .success([])

    public init() {}

    public func fetchTodayDiscoveries() async throws(RepositoryError) -> [TodayDiscovery] {
        fetchTodayDiscoveriesCallCount += 1
        switch fetchTodayDiscoveriesResult {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }

    public func fetchTrendingFeeds() async throws(RepositoryError) -> [TrendingFeed] {
        fetchTrendingFeedsCallCount += 1
        switch fetchTrendingFeedsResult {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }

    public func fetchInterestFeeds() async throws(RepositoryError) -> InterestFeedState {
        fetchInterestFeedsCallCount += 1
        switch fetchInterestFeedsResult {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }

    public func fetchRecommendedNovels() async throws(RepositoryError) -> RecommendedNovelState {
        fetchRecommendedNovelsCallCount += 1
        switch fetchRecommendedNovelsResult {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }

    public func fetchSosoPick() async throws(RepositoryError) -> [SosoPick] {
        fetchSosoPickCallCount += 1
        switch fetchSosoPickResult {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }
}
