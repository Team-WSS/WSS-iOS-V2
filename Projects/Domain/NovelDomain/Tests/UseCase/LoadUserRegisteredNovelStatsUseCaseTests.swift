//
//  LoadUserRegisteredNovelStatsUseCaseTests.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 7/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import NovelDomain
import NovelDomainTesting
import BaseDomain

@Suite
struct LoadUserRegisteredNovelStatsUseCaseTests {

    @Test("다른 유저의 등록된 소설 통계를 정상적으로 불러온다")
    func loadUserRegisteredNovelStatsSuccess() async throws {
        let mock = MockNovelRepository()
        let expected = makeStats()
        mock.fetchUserRegisteredNovelStatsResult = .success(expected)

        let usecase = DefaultLoadUserRegisteredNovelStatsUseCase(novelRepository: mock)
        let result = try await usecase.execute(id: UserID(1003))

        #expect(result.interest == expected.interest)
        #expect(result.watching == expected.watching)
        #expect(result.watched == expected.watched)
        #expect(result.quit == expected.quit)
    }

    @Test("Repository가 전달한 유저 ID로 정확히 한 번 호출된다")
    func repositoryCalledOnceWithGivenID() async throws {
        let mock = MockNovelRepository()
        mock.fetchUserRegisteredNovelStatsResult = .success(makeStats())

        let usecase = DefaultLoadUserRegisteredNovelStatsUseCase(novelRepository: mock)
        let userID = UserID(1003)
        _ = try await usecase.execute(id: userID)

        #expect(mock.fetchedUserRegisteredNovelStatsIDs == [userID])
    }

    @Test("조회에 실패하면 에러를 던진다")
    func loadUserRegisteredNovelStatsFailureThrows() async {
        let mock = MockNovelRepository()
        mock.fetchUserRegisteredNovelStatsResult = .failure(RepositoryError.unknown)

        let usecase = DefaultLoadUserRegisteredNovelStatsUseCase(novelRepository: mock)

        await #expect(throws: RepositoryError.unknown) {
            try await usecase.execute(id: UserID(1))
        }
    }
}

extension LoadUserRegisteredNovelStatsUseCaseTests {
    private func makeStats(
        interest: Int = 10,
        watching: Int = 20,
        watched: Int = 30,
        quit: Int = 5
    ) -> RegisteredNovelStats {
        RegisteredNovelStats(interest: interest, watching: watching, watched: watched, quit: quit)
    }
}
