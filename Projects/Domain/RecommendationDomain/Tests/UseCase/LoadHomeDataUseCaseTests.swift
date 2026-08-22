//
//  LoadHomeDataUseCaseTests.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing
@testable import RecommendationDomain
@testable import BaseDomain
@testable import RecommendationDomainTesting

@Suite
struct LoadHomeDataUseCaseTests {

    // MARK: - 동시성

    /// ⚠️ 이 테스트가 이 UseCase의 **퇴행 방지선**이다.
    /// 과거 `async let`이 순차 `try await`로 펴진 적이 있고(c1e19ed0), 그때 아무 테스트도 깨지지 않아
    /// 홈 로딩이 조용히 2~3배 느려졌다. 같은 시각에 겹쳐 있는 호출 수를 세서 병렬임을 못 박는다.
    @Test("세 호출이 동시에 나간다 — 순차로 펴면 이 테스트가 깨진다")
    func issuesThreeCallsConcurrently() async throws {
        let probe = ConcurrencyProbeRepository()

        let usecase = DefaultLoadHomeDataUseCase(repository: probe)
        _ = try await usecase.execute()

        // 순차라면 항상 1이다.
        #expect(probe.peakConcurrentCalls == 3)
    }

    // MARK: - 협력

    @Test("홈 화면이 그리는 세 가지 API를 모두 호출한다")
    func callsAllThreeApis() async {
        let mock = MockRecommendationRepository()
        mock.fetchTodayDiscoveriesResult = .success([])
        mock.fetchTrendingFeedsResult = .success([])
        mock.fetchRecommendedNovelsResult = .success(.novels([]))

        let usecase = DefaultLoadHomeDataUseCase(repository: mock)
        _ = try? await usecase.execute()

        #expect(mock.fetchTodayDiscoveriesCallCount == 1)
        #expect(mock.fetchTrendingFeedsCallCount == 1)
        #expect(mock.fetchRecommendedNovelsCallCount == 1)
    }

    @Test("홈에 섹션이 없는 관심글은 호출하지 않는다")
    func doesNotCallInterestFeeds() async {
        let mock = MockRecommendationRepository()

        let usecase = DefaultLoadHomeDataUseCase(repository: mock)
        _ = try? await usecase.execute()

        #expect(mock.fetchInterestFeedsCallCount == 0)
    }

    // MARK: - 결과 조립

    @Test("모든 데이터를 성공적으로 불러온다")
    func loadsAllDataSuccessfully() async throws {
        let mock = MockRecommendationRepository()
        mock.fetchTodayDiscoveriesResult = .success([makeTodayDiscovery()])
        mock.fetchTrendingFeedsResult = .success([makeTrendingFeed()])
        mock.fetchRecommendedNovelsResult = .success(.novels([]))

        let usecase = DefaultLoadHomeDataUseCase(repository: mock)
        let homeData = try await usecase.execute()

        #expect(homeData.todayDiscoveries.count == 1)
        #expect(homeData.trendingFeeds.count == 1)
    }

    @Test("로컬에 캐시된 닉네임을 함께 담는다")
    func includesCachedNickname() async throws {
        let mock = MockRecommendationRepository()
        mock.cachedNickname = "웹소소"

        let usecase = DefaultLoadHomeDataUseCase(repository: mock)
        let homeData = try await usecase.execute()

        #expect(homeData.nickname == "웹소소")
    }

    @Test("캐시된 닉네임이 없으면 nil을 담는다")
    func includesNilWhenNicknameIsNotCached() async throws {
        let mock = MockRecommendationRepository()
        mock.cachedNickname = nil

        let usecase = DefaultLoadHomeDataUseCase(repository: mock)
        let homeData = try await usecase.execute()

        #expect(homeData.nickname == nil)
    }

    // MARK: - 실패

    @Test("todayDiscoveries 실패 시 전체를 실패로 반환한다")
    func throwsWhenTodayDiscoveriesFails() async {
        let mock = MockRecommendationRepository()
        mock.fetchTodayDiscoveriesResult = .failure(RepositoryError.unknown)

        let usecase = DefaultLoadHomeDataUseCase(repository: mock)

        await #expect(throws: RepositoryError.unknown) {
            try await usecase.execute()
        }
    }

    @Test("trendingFeeds 실패 시 전체를 실패로 반환한다")
    func throwsWhenTrendingFeedsFails() async {
        let mock = MockRecommendationRepository()
        mock.fetchTodayDiscoveriesResult = .success([makeTodayDiscovery()])
        mock.fetchTrendingFeedsResult = .failure(RepositoryError.unknown)
        mock.fetchRecommendedNovelsResult = .success(.noGenreSettings)

        let usecase = DefaultLoadHomeDataUseCase(repository: mock)

        await #expect(throws: RepositoryError.unknown) {
            try await usecase.execute()
        }
    }

    /// 마지막 호출까지 같은 규칙임을 못 박는다 — 여기만 `try?`로 눙치면 서버 오류가
    /// "선호 장르 미설정"으로 둔갑해 설정 유도 CTA가 뜬다.
    @Test("preferenceGenreNovels 실패 시 전체를 실패로 반환한다")
    func throwsWhenPreferenceGenreNovelsFails() async {
        let mock = MockRecommendationRepository()
        mock.fetchTodayDiscoveriesResult = .success([makeTodayDiscovery()])
        mock.fetchTrendingFeedsResult = .success([makeTrendingFeed()])
        mock.fetchRecommendedNovelsResult = .failure(RepositoryError.serverUnavailable)

        let usecase = DefaultLoadHomeDataUseCase(repository: mock)

        await #expect(throws: RepositoryError.serverUnavailable) {
            try await usecase.execute()
        }
    }

    /// 세 호출은 `async let`으로 동시에 나가므로 하나가 실패해도 나머지는 이미 출발해 있다.
    /// 대신 **닉네임 조회는 세 결과를 다 받은 뒤**라 실패 시 수행되지 않는다 — 로컬 캐시 조회라
    /// 굳이 당길 이유가 없고, 실패 경로에서 불필요한 부수효과를 남기지 않기 위해서다.
    @Test("한 호출이 실패해도 나머지는 이미 나가 있고, 닉네임 조회는 하지 않는다")
    func issuesAllCallsConcurrentlyAndSkipsNicknameOnFailure() async {
        let mock = MockRecommendationRepository()
        mock.fetchTodayDiscoveriesResult = .failure(RepositoryError.networkUnavailable)

        let usecase = DefaultLoadHomeDataUseCase(repository: mock)
        _ = try? await usecase.execute()

        #expect(mock.fetchTodayDiscoveriesCallCount == 1)
        #expect(mock.fetchTrendingFeedsCallCount == 1)
        #expect(mock.fetchRecommendedNovelsCallCount == 1)
        #expect(mock.fetchCachedNicknameCallCount == 0)
    }
}

extension LoadHomeDataUseCaseTests {

    private func makeTodayDiscovery() -> TodayDiscovery {
        TodayDiscovery(
            novelID: NovelID(1),
            novelTitle: "오늘의 발견",
            novelThumbnailImage: nil,
            novelAuthor: "테스트작가",
            novelGenre: .romance,
            publicationStatus: .onGoing,
            keywords: ["빙의"],
            content: .novel,
            contentDescription: "소설 설명"
        )
    }

    private func makeTrendingFeed() -> TrendingFeed {
        TrendingFeed(
            feedID: FeedID(1),
            novelTitle: "테스트 작품",
            novelThumbnailImage: nil,
            novelGenre: .romance,
            description: "뜨는 글 내용",
            isSpoiler: false,
            likeCount: 10,
            commentCount: 3
        )
    }
}

// MARK: - 동시성 계측용 Repository

/// 호출이 들어오고 나갈 때를 세어 **같은 시각에 몇 개가 겹쳐 있었는지**(`peakConcurrentCalls`)를 남긴다.
/// 벽시계 시간을 재면 머신 부하에 흔들리지만, 겹친 개수는 병렬이면 3 / 순차면 1로 결정적이다.
private final class ConcurrencyProbeRepository: RecommendationRepository, @unchecked Sendable {

    private let lock = NSLock()
    private var inFlight = 0
    private var peak = 0

    var peakConcurrentCalls: Int { withLock { peak } }

    func fetchTodayDiscoveries() async throws(RepositoryError) -> [TodayDiscovery] {
        await overlapping([])
    }

    func fetchTrendingFeeds() async throws(RepositoryError) -> [TrendingFeed] {
        await overlapping([])
    }

    func fetchInterestFeeds() async throws(RepositoryError) -> InterestFeedState {
        await overlapping(.noInterestSettings)
    }

    func fetchPreferenceGenreNovels() async throws(RepositoryError) -> PreferenceGenreNovelState {
        await overlapping(.noGenreSettings)
    }

    func fetchSosoPick() async throws(RepositoryError) -> [SosoPick] {
        await overlapping([])
    }

    func fetchCachedNickname() -> String? { nil }

    /// 겹칠 틈을 만들기 위해 잠깐 머문다 — 이 지연이 없으면 셋 다 시작 전에 끝나버려 겹침이 안 잡힌다.
    private func overlapping<T>(_ value: T) async -> T {
        enter()
        try? await Task.sleep(nanoseconds: 30_000_000)
        leave()
        return value
    }

    private func enter() {
        withLock {
            inFlight += 1
            peak = max(peak, inFlight)
        }
    }

    private func leave() {
        withLock { inFlight -= 1 }
    }

    /// `NSLock`은 async 컨텍스트에서 직접 쓸 수 없어 동기 함수로 감싼다.
    private func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
}
