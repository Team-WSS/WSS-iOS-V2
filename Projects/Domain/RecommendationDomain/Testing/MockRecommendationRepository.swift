//
//  MockRecommendationRepository.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain
import RecommendationDomain

/// 추천 저장소 가짜 객체. 전부 조회라 정해 둔 값만 돌려주고 호출을 기록하지 않는다(Stub).
///
/// 값은 실행 전에 정해 두고 실행 중에는 읽기만 한다 — `LoadHomeDataUseCase`가 세 조회를 동시에 불러도
/// 쓰기가 겹치지 않아 락 없이 `@unchecked Sendable`로 둔다.
public final class MockRecommendationRepository: RecommendationRepository, @unchecked Sendable {

    public var cachedNickname: String?

    public var fetchTodayDiscoveriesResult: Result<[TodayDiscovery], RepositoryError> = .success([])
    public var fetchTrendingFeedsResult: Result<[TrendingFeed], RepositoryError> = .success([])
    public var fetchInterestFeedsResult: Result<InterestFeedState, RepositoryError> = .success(.noInterestSettings)
    public var fetchRecommendedNovelsResult: Result<PreferenceGenreNovelState, RepositoryError> = .success(.noGenreSettings)
    public var fetchSosoPickResult: Result<[SosoPick], RepositoryError> = .success([])

    public init() {}

    public func fetchTodayDiscoveries() async throws(RepositoryError) -> [TodayDiscovery] {
        try fetchTodayDiscoveriesResult.get()
    }

    public func fetchTrendingFeeds() async throws(RepositoryError) -> [TrendingFeed] {
        try fetchTrendingFeedsResult.get()
    }

    public func fetchInterestFeeds() async throws(RepositoryError) -> InterestFeedState {
        try fetchInterestFeedsResult.get()
    }

    public func fetchPreferenceGenreNovels() async throws(RepositoryError) -> PreferenceGenreNovelState {
        try fetchRecommendedNovelsResult.get()
    }

    public func fetchSosoPick() async throws(RepositoryError) -> [SosoPick] {
        try fetchSosoPickResult.get()
    }

    public func fetchCachedNickname() -> String? {
        cachedNickname
    }
}
