//
//  LoadHomeDataUseCaseTests.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

import BaseDomain
import RecommendationDomain
import RecommendationDomainTesting

@Suite("홈 데이터 불러오기")
struct LoadHomeDataUseCaseTests {

    @Test("추천 세 가지(오늘의 발견·지금 뜨는 글·선호 장르 작품)를 하나로 모아 돌려준다")
    func combinesThreeRecommendations() async throws {
        let repository = MockRecommendationRepository()
        // 세 목록의 id를 서로 다르게 둬서, 각 목록이 제자리에 담겼는지 보이게 한다.
        repository.fetchTodayDiscoveriesResult = .success([makeTodayDiscovery(id: 1)])
        repository.fetchTrendingFeedsResult = .success([makeTrendingFeed(id: 2)])
        repository.fetchRecommendedNovelsResult = .success(.novels([makePreferenceGenreNovel(id: 3)]))
        let useCase = DefaultLoadHomeDataUseCase(repository: repository)

        let homeData = try await useCase.execute()

        #expect(homeData.todayDiscoveries.map(\.novelID) == [NovelID(1)])
        #expect(homeData.trendingFeeds.map(\.feedID) == [FeedID(2)])
        #expect(novelIDs(in: homeData.preferenceGenreNovelState) == [NovelID(3)])
    }

    @Test("로컬에 저장된 닉네임을 함께 담는다")
    func includesCachedNickname() async throws {
        let repository = MockRecommendationRepository()
        repository.cachedNickname = "웹소소"
        let useCase = DefaultLoadHomeDataUseCase(repository: repository)

        let homeData = try await useCase.execute()

        #expect(homeData.nickname == "웹소소")
    }

    @Test("저장된 닉네임이 없으면 닉네임이 비어 있다")
    func nicknameIsEmptyWhenNotCached() async throws {
        let repository = MockRecommendationRepository()
        repository.cachedNickname = nil
        let useCase = DefaultLoadHomeDataUseCase(repository: repository)

        let homeData = try await useCase.execute()

        #expect(homeData.nickname == nil)
    }

    /// ⚠️ 이 UseCase의 퇴행 방지선이다. 세 호출이 순차로 펴진 적이 있는데(c1e19ed0) 그때 아무 테스트도
    /// 깨지지 않아 홈 로딩이 조용히 2~3배 느려졌다. 시간이 아니라 "같은 시각에 겹친 호출 수"를 세서
    /// 머신 부하에 흔들리지 않게 한다(병렬이면 3, 순차면 1).
    @Test("세 가지를 동시에 불러온다")
    func issuesThreeCallsConcurrently() async throws {
        let probe = ConcurrencyProbeRepository()
        let useCase = DefaultLoadHomeDataUseCase(repository: probe)

        _ = try await useCase.execute()

        #expect(probe.peakConcurrentCalls == 3)
    }

    /// 홈엔 관심글 섹션이 없다(#179). 관심글까지 부르면 그 하나가 실패할 때 홈 전체가 실패한다.
    /// 그래서 관심글이 실패하게 해 두고, 홈 데이터가 그래도 오는지로 부르지 않았음을 확인한다.
    @Test("홈은 관심글을 불러오지 않는다")
    func doesNotLoadInterestFeeds() async {
        let repository = MockRecommendationRepository()
        repository.fetchInterestFeedsResult = .failure(.serverUnavailable)
        let useCase = DefaultLoadHomeDataUseCase(repository: repository)

        await #expect(throws: Never.self) {
            try await useCase.execute()
        }
    }

    @Test("오늘의 발견을 불러오지 못하면 그 에러로 실패한다")
    func failsWhenTodayDiscoveriesFail() async {
        let repository = MockRecommendationRepository()
        repository.fetchTodayDiscoveriesResult = .failure(.networkUnavailable)
        let useCase = DefaultLoadHomeDataUseCase(repository: repository)

        await #expect(throws: RepositoryError.networkUnavailable) {
            try await useCase.execute()
        }
    }

    @Test("지금 뜨는 글을 불러오지 못하면 그 에러로 실패한다")
    func failsWhenTrendingFeedsFail() async {
        let repository = MockRecommendationRepository()
        repository.fetchTrendingFeedsResult = .failure(.serverUnavailable)
        let useCase = DefaultLoadHomeDataUseCase(repository: repository)

        await #expect(throws: RepositoryError.serverUnavailable) {
            try await useCase.execute()
        }
    }

    /// 이 실패를 삼키고 빈 값으로 채우면 서버 오류가 "선호 장르 미설정"처럼 보여 설정 유도 카드가 뜬다.
    @Test("선호 장르 작품을 불러오지 못하면 그 에러로 실패한다")
    func failsWhenPreferenceGenreNovelsFail() async {
        let repository = MockRecommendationRepository()
        repository.fetchRecommendedNovelsResult = .failure(.invalidData)
        let useCase = DefaultLoadHomeDataUseCase(repository: repository)

        await #expect(throws: RepositoryError.invalidData) {
            try await useCase.execute()
        }
    }
}

// MARK: - Helper

private func novelIDs(in state: PreferenceGenreNovelState) -> [NovelID]? {
    guard case .novels(let novels) = state else { return nil }
    return novels.map(\.novelID)
}

private func makeTodayDiscovery(id: Int) -> TodayDiscovery {
    TodayDiscovery(
        novelID: NovelID(id),
        novelTitle: "오늘의 발견",
        novelThumbnailImage: nil,
        novelAuthor: "작가",
        novelGenre: .romance,
        publicationStatus: .onGoing,
        keywords: [],
        content: .novel,
        contentDescription: "작품 소개"
    )
}

private func makeTrendingFeed(id: Int) -> TrendingFeed {
    TrendingFeed(
        feedID: FeedID(id),
        novelTitle: "작품",
        novelThumbnailImage: nil,
        novelGenre: .romance,
        description: "지금 뜨는 글",
        isSpoiler: false,
        likeCount: 0,
        commentCount: 0
    )
}

private func makePreferenceGenreNovel(id: Int) -> PreferenceGenreNovel {
    PreferenceGenreNovel(
        novelID: NovelID(id),
        novelTitle: "선호 장르 작품",
        novelThumbnailImage: nil,
        novelAuthors: [],
        interestCount: 0,
        ratingCount: 0,
        rating: 0
    )
}

// MARK: - 동시성 계측용 저장소

/// 호출이 들어오고 나갈 때를 세어 같은 시각에 몇 개가 겹쳐 있었는지(`peakConcurrentCalls`)를 남긴다.
/// 이 테스트 하나만 쓰는 계측 도구라 `Testing/`이 아니라 여기 둔다.
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

    /// 겹칠 틈을 만들려고 잠깐 머문다 — 이 지연이 없으면 다음 호출이 시작되기 전에 끝나 겹침이 안 잡힌다.
    private func overlapping<T>(_ value: T) async -> T {
        withLock {
            inFlight += 1
            peak = max(peak, inFlight)
        }
        try? await Task.sleep(nanoseconds: 30_000_000)
        withLock { inFlight -= 1 }
        return value
    }

    /// `NSLock`은 async 컨텍스트에서 직접 쓸 수 없어 동기 함수로 감싼다.
    private func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
}
