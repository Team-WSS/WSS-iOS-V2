//
//  LoadHomeDataUseCaseTests.swift
//  RecommendationDomain
//
//  Created by Seoyeon Choi on 2/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import RecommendationDomain
@testable import BaseDomain
@testable import RecommendationDomainTesting

@Suite
struct LoadHomeDataUseCaseTests {

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

    /// 순차 호출이라는 사실 자체가 명세다 — 병렬로 바꾸면 실패한 뒤에도 나머지 요청이 나간다.
    @Test("앞선 호출이 실패하면 뒤따르는 호출과 닉네임 조회를 하지 않는다")
    func stopsRemainingCallsAfterFailure() async {
        let mock = MockRecommendationRepository()
        mock.fetchTodayDiscoveriesResult = .failure(RepositoryError.networkUnavailable)

        let usecase = DefaultLoadHomeDataUseCase(repository: mock)
        _ = try? await usecase.execute()

        #expect(mock.fetchTrendingFeedsCallCount == 0)
        #expect(mock.fetchRecommendedNovelsCallCount == 0)
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
