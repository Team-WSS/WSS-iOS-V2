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

/// `LoadHomeDataUseCase`가 세 호출을 `async let`으로 **동시에** 부르므로 카운터가 동시에 증가한다.
/// 락 없이 두면 호출 횟수 자체를 믿을 수 없어 테스트가 조용히 흔들린다.
public final class MockRecommendationRepository: RecommendationRepository, @unchecked Sendable {

    private struct State {
        var fetchTodayDiscoveriesCallCount = 0
        var fetchTrendingFeedsCallCount = 0
        var fetchInterestFeedsCallCount = 0
        var fetchRecommendedNovelsCallCount = 0
        var fetchSosoPickCallCount = 0
        var fetchCachedNicknameCallCount = 0

        var cachedNickname: String?

        var fetchTodayDiscoveriesResult: Result<[TodayDiscovery], RepositoryError> = .success([])
        var fetchTrendingFeedsResult: Result<[TrendingFeed], RepositoryError> = .success([])
        var fetchInterestFeedsResult: Result<InterestFeedState, RepositoryError> = .success(.noInterestSettings)
        var fetchRecommendedNovelsResult: Result<PreferenceGenreNovelState, RepositoryError> = .success(.noGenreSettings)
        var fetchSosoPickResult: Result<[SosoPick], RepositoryError> = .success([])
    }

    private let lock = NSLock()
    private var state = State()

    public init() {}

    // MARK: - 호출 횟수

    public var fetchTodayDiscoveriesCallCount: Int { withLock { state.fetchTodayDiscoveriesCallCount } }
    public var fetchTrendingFeedsCallCount: Int { withLock { state.fetchTrendingFeedsCallCount } }
    public var fetchInterestFeedsCallCount: Int { withLock { state.fetchInterestFeedsCallCount } }
    public var fetchRecommendedNovelsCallCount: Int { withLock { state.fetchRecommendedNovelsCallCount } }
    public var fetchSosoPickCallCount: Int { withLock { state.fetchSosoPickCallCount } }
    public var fetchCachedNicknameCallCount: Int { withLock { state.fetchCachedNicknameCallCount } }

    // MARK: - 스텁

    public var cachedNickname: String? {
        get { withLock { state.cachedNickname } }
        set { withLock { state.cachedNickname = newValue } }
    }

    public var fetchTodayDiscoveriesResult: Result<[TodayDiscovery], RepositoryError> {
        get { withLock { state.fetchTodayDiscoveriesResult } }
        set { withLock { state.fetchTodayDiscoveriesResult = newValue } }
    }

    public var fetchTrendingFeedsResult: Result<[TrendingFeed], RepositoryError> {
        get { withLock { state.fetchTrendingFeedsResult } }
        set { withLock { state.fetchTrendingFeedsResult = newValue } }
    }

    public var fetchInterestFeedsResult: Result<InterestFeedState, RepositoryError> {
        get { withLock { state.fetchInterestFeedsResult } }
        set { withLock { state.fetchInterestFeedsResult = newValue } }
    }

    public var fetchRecommendedNovelsResult: Result<PreferenceGenreNovelState, RepositoryError> {
        get { withLock { state.fetchRecommendedNovelsResult } }
        set { withLock { state.fetchRecommendedNovelsResult = newValue } }
    }

    public var fetchSosoPickResult: Result<[SosoPick], RepositoryError> {
        get { withLock { state.fetchSosoPickResult } }
        set { withLock { state.fetchSosoPickResult = newValue } }
    }

    // MARK: - RecommendationRepository

    public func fetchTodayDiscoveries() async throws(RepositoryError) -> [TodayDiscovery] {
        try resolve(withLock { state.fetchTodayDiscoveriesCallCount += 1; return state.fetchTodayDiscoveriesResult })
    }

    public func fetchTrendingFeeds() async throws(RepositoryError) -> [TrendingFeed] {
        try resolve(withLock { state.fetchTrendingFeedsCallCount += 1; return state.fetchTrendingFeedsResult })
    }

    public func fetchInterestFeeds() async throws(RepositoryError) -> InterestFeedState {
        try resolve(withLock { state.fetchInterestFeedsCallCount += 1; return state.fetchInterestFeedsResult })
    }

    public func fetchPreferenceGenreNovels() async throws(RepositoryError) -> PreferenceGenreNovelState {
        try resolve(withLock { state.fetchRecommendedNovelsCallCount += 1; return state.fetchRecommendedNovelsResult })
    }

    public func fetchSosoPick() async throws(RepositoryError) -> [SosoPick] {
        try resolve(withLock { state.fetchSosoPickCallCount += 1; return state.fetchSosoPickResult })
    }

    public func fetchCachedNickname() -> String? {
        withLock {
            state.fetchCachedNicknameCallCount += 1
            return state.cachedNickname
        }
    }

    // MARK: - Helper

    /// `NSLock`은 async 컨텍스트에서 직접 쓸 수 없어 동기 함수로 감싼다.
    private func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }

    private func resolve<T>(_ result: Result<T, RepositoryError>) throws(RepositoryError) -> T {
        switch result {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }
}
