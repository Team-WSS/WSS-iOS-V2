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

public enum MockError: Error, Equatable {
    case networkError
    case serverError
}

public final class MockRecommendationRepository: RecommendationRepository {

    public var fetchTodayDiscoveriesCallCount = 0
    public var fetchTrendingFeedsCallCount = 0
    public var fetchInterestFeedsCallCount = 0
    public var fetchRecommendedNovelsCallCount = 0
    public var fetchSosoPickCallCount = 0

    public var fetchTodayDiscoveriesResult: Result<[TodayDiscovery], Error> = .success([])
    public var fetchTrendingFeedsResult: Result<[TrendingFeed], Error> = .success([])
    public var fetchInterestFeedsResult: Result<InterestFeedState, Error> = .success(.noInterestSettings)
    public var fetchRecommendedNovelsResult: Result<RecommendedNovelState, Error> = .success(.noGenreSettings)
    public var fetchSosoPickResult: Result<[SosoPick], Error> = .success([])

    public init() {}

    public func fetchTodayDiscoveries() async throws -> [TodayDiscovery] {
        fetchTodayDiscoveriesCallCount += 1
        switch fetchTodayDiscoveriesResult {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }

    public func fetchTrendingFeeds() async throws -> [TrendingFeed] {
        fetchTrendingFeedsCallCount += 1
        switch fetchTrendingFeedsResult {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }

    public func fetchInterestFeeds() async throws -> InterestFeedState {
        fetchInterestFeedsCallCount += 1
        switch fetchInterestFeedsResult {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }

    public func fetchRecommendedNovels() async throws -> RecommendedNovelState {
        fetchRecommendedNovelsCallCount += 1
        switch fetchRecommendedNovelsResult {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }

    public func fetchSosoPick() async throws -> [SosoPick] {
        fetchSosoPickCallCount += 1
        switch fetchSosoPickResult {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }
}
