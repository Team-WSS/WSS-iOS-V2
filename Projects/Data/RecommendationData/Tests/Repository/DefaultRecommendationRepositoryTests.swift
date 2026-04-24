import Foundation
import Testing
@testable import RecommendationData
@testable import RecommendationDataTesting
import RecommendationDomain
import BaseDomain
import BaseData
import Networking

@Suite("DefaultRecommendationRepository")
struct DefaultRecommendationRepositoryTests {

    // MARK: - Helpers

    private func makeRepository(
        service: MockRecommendationService,
        logger: DataLogger? = nil
    ) -> DefaultRecommendationRepository {
        DefaultRecommendationRepository(service: service, logger: logger)
    }

    private func makeLogger() -> (DataLogger, MockLogger) {
        let mock = MockLogger()
        let logger = DataLogger(moduleName: "Recommendation", underlying: mock)
        return (logger, mock)
    }

    private func makeTodayDiscoveryResponse() -> TodayDiscoveryNovelsResponse {
        TodayDiscoveryNovelsResponse(
            popularNovels: [
                TodayDiscoveryNovelResponse(
                    novelId: 1,
                    title: "오늘의 발견",
                    novelImage: "https://example.com/novel.jpg",
                    avatarImage: nil,
                    nickname: nil,
                    feedContent: "소설 소개"
                )
            ]
        )
    }

    private func makeTrendingFeedsResponse() -> TrendingFeedsResponse {
        TrendingFeedsResponse(
            popularFeeds: [
                TrendingFeedResponse(
                    feedId: 1,
                    feedContent: "인기 피드",
                    likeCount: 100,
                    commentCount: 20,
                    isSpoiler: false,
                    isPublic: true
                )
            ]
        )
    }

    private func makeInterestFeedsResponse() -> InterestFeedsResponse {
        InterestFeedsResponse(
            recommendFeeds: [
                InterestFeedResponse(
                    novelId: 1,
                    novelTitle: "관심 소설",
                    novelImage: "https://example.com/novel.jpg",
                    novelRating: 4.5,
                    novelRatingCount: 100,
                    nickname: "유저",
                    avatarImage: "https://example.com/avatar.jpg",
                    feedContent: "재밌어요"
                )
            ],
            message: "SUCCESS"
        )
    }

    private func makePreferenceGenreNovelsResponse() -> PreferenceGenreNovelsResponse {
        PreferenceGenreNovelsResponse(
            tasteNovels: [
                PreferenceGenreNovelResponse(
                    novelId: 1,
                    title: "선호 장르 소설",
                    author: "작가A",
                    novelImage: "https://example.com/novel.jpg",
                    interestCount: 200,
                    novelRating: 4.0,
                    novelRatingCount: 300
                )
            ]
        )
    }

    private func makeSosopickNovelsResponse() -> SosopickNovelsResponse {
        SosopickNovelsResponse(
            sosoPicks: [
                SosopickNovelResponse(
                    novelId: 1,
                    novelImage: "https://example.com/novel.jpg",
                    title: "소소픽 소설"
                )
            ]
        )
    }

    // MARK: - fetchTodayDiscoveries

    @Test("오늘의 발견 조회에 성공하면 TodayDiscovery 배열을 반환한다")
    func fetchesTodayDiscoveriesSuccessfully() async throws {
        let service = MockRecommendationService()
        let (logger, mockLogger) = makeLogger()
        service.getTodayDiscoveryResult = .success(makeTodayDiscoveryResponse())

        let sut = makeRepository(service: service, logger: logger)

        let result = try await sut.fetchTodayDiscoveries()

        #expect(service.todayDiscoveryCallCount == 1)
        #expect(result.count == 1)
        #expect(result.first?.novelTitle == "오늘의 발견")
        #expect(mockLogger.errorMessages.isEmpty)
    }

    @Test("오늘의 발견 조회 시 networking 에러가 발생하면 RepositoryError로 변환하고 network 로그를 남긴다")
    func translatesNetworkingErrorOnFetchTodayDiscoveries() async {
        let service = MockRecommendationService()
        let (logger, mockLogger) = makeLogger()
        service.getTodayDiscoveryResult = .failure(
            NetworkingError.responseFailure(code: 404, body: nil)
        )

        let sut = makeRepository(service: service, logger: logger)

        await #expect(throws: RepositoryError.notFound) {
            _ = try await sut.fetchTodayDiscoveries()
        }

        #expect(mockLogger.errorMessages.count == 1)
        #expect(mockLogger.errorMessages.first?.contains("network error") == true)
    }

    @Test("오늘의 발견 조회 시 알 수 없는 에러가 발생하면 unknown 에러를 던지고 unknown 로그를 남긴다")
    func throwsUnknownWhenFetchTodayDiscoveriesFails() async {
        let service = MockRecommendationService()
        let (logger, mockLogger) = makeLogger()
        service.getTodayDiscoveryResult = .failure(MockError.sample)

        let sut = makeRepository(service: service, logger: logger)

        await #expect(throws: RepositoryError.unknown) {
            _ = try await sut.fetchTodayDiscoveries()
        }

        #expect(mockLogger.errorMessages.count == 1)
        #expect(mockLogger.errorMessages.first?.contains("unknown error") == true)
    }

    // MARK: - fetchTrendingFeeds

    @Test("지금 뜨는 글 조회에 성공하면 TrendingFeed 배열을 반환한다")
    func fetchesTrendingFeedsSuccessfully() async throws {
        let service = MockRecommendationService()
        let (logger, mockLogger) = makeLogger()
        service.getTrendingFeedsResult = .success(makeTrendingFeedsResponse())

        let sut = makeRepository(service: service, logger: logger)

        let result = try await sut.fetchTrendingFeeds()

        #expect(service.trendingFeedsCallCount == 1)
        #expect(result.count == 1)
        #expect(result.first?.feedID == FeedID(1))
        #expect(mockLogger.errorMessages.isEmpty)
    }

    @Test("지금 뜨는 글 조회 시 networking 에러가 발생하면 RepositoryError로 변환하고 network 로그를 남긴다")
    func translatesNetworkingErrorOnFetchTrendingFeeds() async {
        let service = MockRecommendationService()
        let (logger, mockLogger) = makeLogger()
        service.getTrendingFeedsResult = .failure(
            NetworkingError.responseFailure(code: 401, body: nil)
        )

        let sut = makeRepository(service: service, logger: logger)

        await #expect(throws: RepositoryError.authenticationRequired) {
            _ = try await sut.fetchTrendingFeeds()
        }

        #expect(mockLogger.errorMessages.count == 1)
        #expect(mockLogger.errorMessages.first?.contains("network error") == true)
    }

    @Test("지금 뜨는 글 조회 시 알 수 없는 에러가 발생하면 unknown 에러를 던지고 unknown 로그를 남긴다")
    func throwsUnknownWhenFetchTrendingFeedsFails() async {
        let service = MockRecommendationService()
        let (logger, mockLogger) = makeLogger()
        service.getTrendingFeedsResult = .failure(MockError.sample)

        let sut = makeRepository(service: service, logger: logger)

        await #expect(throws: RepositoryError.unknown) {
            _ = try await sut.fetchTrendingFeeds()
        }

        #expect(mockLogger.errorMessages.count == 1)
        #expect(mockLogger.errorMessages.first?.contains("unknown error") == true)
    }

    // MARK: - fetchInterestFeeds

    @Test("관심글 조회에 성공하면 InterestFeedState를 반환한다")
    func fetchesInterestFeedsSuccessfully() async throws {
        let service = MockRecommendationService()
        let (logger, mockLogger) = makeLogger()
        service.getInterestFeedsResult = .success(makeInterestFeedsResponse())

        let sut = makeRepository(service: service, logger: logger)

        let result = try await sut.fetchInterestFeeds()

        #expect(service.interestFeedsCallCount == 1)
        guard case .feeds(let feeds) = result else {
            Issue.record("feeds 상태여야 합니다")
            return
        }
        #expect(feeds.count == 1)
        #expect(mockLogger.errorMessages.isEmpty)
    }

    @Test("관심글 조회 시 networking 에러가 발생하면 RepositoryError로 변환하고 network 로그를 남긴다")
    func translatesNetworkingErrorOnFetchInterestFeeds() async {
        let service = MockRecommendationService()
        let (logger, mockLogger) = makeLogger()
        service.getInterestFeedsResult = .failure(
            NetworkingError.responseFailure(code: 500, body: nil)
        )

        let sut = makeRepository(service: service, logger: logger)

        await #expect(throws: RepositoryError.serverUnavailable) {
            _ = try await sut.fetchInterestFeeds()
        }

        #expect(mockLogger.errorMessages.count == 1)
        #expect(mockLogger.errorMessages.first?.contains("network error") == true)
    }

    @Test("관심글 조회 시 알 수 없는 에러가 발생하면 unknown 에러를 던지고 unknown 로그를 남긴다")
    func throwsUnknownWhenFetchInterestFeedsFails() async {
        let service = MockRecommendationService()
        let (logger, mockLogger) = makeLogger()
        service.getInterestFeedsResult = .failure(MockError.sample)

        let sut = makeRepository(service: service, logger: logger)

        await #expect(throws: RepositoryError.unknown) {
            _ = try await sut.fetchInterestFeeds()
        }

        #expect(mockLogger.errorMessages.count == 1)
        #expect(mockLogger.errorMessages.first?.contains("unknown error") == true)
    }

    // MARK: - fetchPreferenceGenreNovels

    @Test("선호 장르 소설 조회에 성공하면 PreferenceGenreNovelState를 반환한다")
    func fetchesPreferenceGenreNovelsSuccessfully() async throws {
        let service = MockRecommendationService()
        let (logger, mockLogger) = makeLogger()
        service.getPreferenceGenreNovelsResult = .success(makePreferenceGenreNovelsResponse())

        let sut = makeRepository(service: service, logger: logger)

        let result = try await sut.fetchPreferenceGenreNovels()

        #expect(service.preferenceGenreNovelsCallCount == 1)
        guard case .novels(let novels) = result else {
            Issue.record("novels 상태여야 합니다")
            return
        }
        #expect(novels.count == 1)
        #expect(mockLogger.errorMessages.isEmpty)
    }

    @Test("선호 장르 소설 조회 시 networking 에러가 발생하면 RepositoryError로 변환하고 network 로그를 남긴다")
    func translatesNetworkingErrorOnFetchPreferenceGenreNovels() async {
        let service = MockRecommendationService()
        let (logger, mockLogger) = makeLogger()
        service.getPreferenceGenreNovelsResult = .failure(
            NetworkingError.decoding
        )

        let sut = makeRepository(service: service, logger: logger)

        await #expect(throws: RepositoryError.invalidData) {
            _ = try await sut.fetchPreferenceGenreNovels()
        }

        #expect(mockLogger.errorMessages.count == 1)
        #expect(mockLogger.errorMessages.first?.contains("network error") == true)
    }

    @Test("선호 장르 소설 조회 시 알 수 없는 에러가 발생하면 unknown 에러를 던지고 unknown 로그를 남긴다")
    func throwsUnknownWhenFetchPreferenceGenreNovelsFails() async {
        let service = MockRecommendationService()
        let (logger, mockLogger) = makeLogger()
        service.getPreferenceGenreNovelsResult = .failure(MockError.sample)

        let sut = makeRepository(service: service, logger: logger)

        await #expect(throws: RepositoryError.unknown) {
            _ = try await sut.fetchPreferenceGenreNovels()
        }

        #expect(mockLogger.errorMessages.count == 1)
        #expect(mockLogger.errorMessages.first?.contains("unknown error") == true)
    }

    // MARK: - fetchSosoPick

    @Test("소소픽 조회에 성공하면 SosoPick 배열을 반환한다")
    func fetchesSosoPickSuccessfully() async throws {
        let service = MockRecommendationService()
        let (logger, mockLogger) = makeLogger()
        service.getSosopickNovelsResult = .success(makeSosopickNovelsResponse())

        let sut = makeRepository(service: service, logger: logger)

        let result = try await sut.fetchSosoPick()

        #expect(service.sosopickNovelsCallCount == 1)
        #expect(result.count == 1)
        #expect(result.first?.novelTitle == "소소픽 소설")
        #expect(mockLogger.errorMessages.isEmpty)
    }

    @Test("소소픽 조회 시 networking 에러가 발생하면 RepositoryError로 변환하고 network 로그를 남긴다")
    func translatesNetworkingErrorOnFetchSosoPick() async {
        let service = MockRecommendationService()
        let (logger, mockLogger) = makeLogger()
        service.getSosopickNovelsResult = .failure(
            NetworkingError.responseFailure(code: 500, body: nil)
        )

        let sut = makeRepository(service: service, logger: logger)

        await #expect(throws: RepositoryError.serverUnavailable) {
            _ = try await sut.fetchSosoPick()
        }

        #expect(mockLogger.errorMessages.count == 1)
        #expect(mockLogger.errorMessages.first?.contains("network error") == true)
    }

    @Test("소소픽 조회 시 알 수 없는 에러가 발생하면 unknown 에러를 던지고 unknown 로그를 남긴다")
    func throwsUnknownWhenFetchSosoPickFails() async {
        let service = MockRecommendationService()
        let (logger, mockLogger) = makeLogger()
        service.getSosopickNovelsResult = .failure(MockError.sample)

        let sut = makeRepository(service: service, logger: logger)

        await #expect(throws: RepositoryError.unknown) {
            _ = try await sut.fetchSosoPick()
        }

        #expect(mockLogger.errorMessages.count == 1)
        #expect(mockLogger.errorMessages.first?.contains("unknown error") == true)
    }
}
