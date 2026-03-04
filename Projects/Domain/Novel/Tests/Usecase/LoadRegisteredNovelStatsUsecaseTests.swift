//
//  LoadRegisteredNovelStatsUsecaseTests.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import NovelDomain
@testable import BaseDomain
import NovelDomainTesting

@Suite
struct LoadRegisteredNovelStatsUsecaseTests {

    @Test("등록된 소설 통계를 정상적으로 불러온다")
    func loadRegisteredNovelStatsSuccess() async throws {
        let mock = MockNovelRepository()
        let expected = makeStats()
        mock.fetchRegisteredNovelStatsResult = .success(expected)

        let usecase = DefaultLoadRegisteredNovelStatsUsecase(novelRepository: mock)
        let result = try await usecase.execute()

        #expect(result.interest == expected.interest)
        #expect(result.watching == expected.watching)
        #expect(result.watched == expected.watched)
        #expect(result.quit == expected.quit)
    }

    @Test("Repository가 정확히 한 번 호출된다")
    func repositoryCalledOnce() async throws {
        let mock = MockNovelRepository()
        mock.fetchRegisteredNovelStatsResult = .success(makeStats())

        let usecase = DefaultLoadRegisteredNovelStatsUsecase(novelRepository: mock)
        _ = try await usecase.execute()

        #expect(mock.fetchRegisteredNovelStatsCallCount == 1)
    }

    @Test("조회에 실패하면 에러를 던진다")
    func loadRegisteredNovelStatsFailureThrows() async {
        let mock = MockNovelRepository()
        mock.fetchRegisteredNovelStatsResult = .failure(TestError.networkFail)

        let usecase = DefaultLoadRegisteredNovelStatsUsecase(novelRepository: mock)

        await #expect(throws: TestError.networkFail) {
            try await usecase.execute()
        }
    }
}

extension LoadRegisteredNovelStatsUsecaseTests {

    private enum TestError: Error { case networkFail }

    private func makeStats(
        interest: Int = 10,
        watching: Int = 20,
        watched: Int = 30,
        quit: Int = 5
    ) -> RegisteredNovelStats {
        RegisteredNovelStats(interest: interest, watching: watching, watched: watched, quit: quit)
    }
}
