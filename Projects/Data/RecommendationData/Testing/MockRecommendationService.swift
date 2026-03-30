@testable import RecommendationData

final class MockRecommendationService: RecommendationService {
    var getTodayDiscoveryResult: Result<TodayDiscoveryNovelsResponse, Error>!
    var getTrendingFeedsResult: Result<TrendingFeedsResponse, Error>!
    var getInterestFeedsResult: Result<InterestFeedsResponse, Error>!
    var getPreferenceGenreNovelsResult: Result<PreferenceGenreNovelsResponse, Error>!
    var getSosopickNovelsResult: Result<SosopickNovelsResponse, Error>!

    private(set) var todayDiscoveryCallCount = 0
    private(set) var trendingFeedsCallCount = 0
    private(set) var interestFeedsCallCount = 0
    private(set) var preferenceGenreNovelsCallCount = 0
    private(set) var sosopickNovelsCallCount = 0

    func getTodayDiscovery() async throws -> TodayDiscoveryNovelsResponse {
        todayDiscoveryCallCount += 1
        return try getTodayDiscoveryResult.get()
    }

    func getTrendingFeeds() async throws -> TrendingFeedsResponse {
        trendingFeedsCallCount += 1
        return try getTrendingFeedsResult.get()
    }

    func getInterestFeeds() async throws -> InterestFeedsResponse {
        interestFeedsCallCount += 1
        return try getInterestFeedsResult.get()
    }

    func getPreferenceGenreNovels() async throws -> PreferenceGenreNovelsResponse {
        preferenceGenreNovelsCallCount += 1
        return try getPreferenceGenreNovelsResult.get()
    }

    func getSosopickNovels() async throws -> SosopickNovelsResponse {
        sosopickNovelsCallCount += 1
        return try getSosopickNovelsResult.get()
    }
}
