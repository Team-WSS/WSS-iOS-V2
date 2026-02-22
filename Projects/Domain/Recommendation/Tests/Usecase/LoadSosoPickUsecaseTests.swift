//
//  LoadSosoPickUsecaseTests.swift
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
struct LoadSosoPickUsecaseTests {

    @Test("소소픽을 성공적으로 불러온다")
    func loadsSosoPickSuccessfully() async throws {
        let mock = MockRecommendationRepository()
        let expectedPicks = [makeSosoPick(novelID: NovelID(1)), makeSosoPick(novelID: NovelID(2))]
        mock.fetchSosoPickResult = .success(expectedPicks)

        let usecase = DefaultLoadSosoPickUsecase(recommendationRepository: mock)
        let result = try await usecase.execute()

        #expect(result.count == 2)
        #expect(mock.fetchSosoPickCallCount == 1)
    }

    @Test("소소픽 목록이 비어있어도 정상적으로 반환한다")
    func returnsEmptySosoPickListNormally() async throws {
        let mock = MockRecommendationRepository()
        mock.fetchSosoPickResult = .success([])

        let usecase = DefaultLoadSosoPickUsecase(recommendationRepository: mock)
        let result = try await usecase.execute()

        #expect(result.isEmpty)
    }

    @Test("소소픽 불러오기에 실패하면 에러를 던진다")
    func throwsErrorWhenLoadSosoPickFails() async {
        let mock = MockRecommendationRepository()
        mock.fetchSosoPickResult = .failure(MockError.networkError)

        let usecase = DefaultLoadSosoPickUsecase(recommendationRepository: mock)

        await #expect(throws: MockError.networkError) {
            try await usecase.execute()
        }
    }
}

extension LoadSosoPickUsecaseTests {
    private func makeSosoPick(novelID: NovelID = NovelID(1)) -> SosoPick {
        SosoPick(
            novelID: novelID,
            novelTitle: "소소 픽 소설",
            novelThumbnailimage: nil
        )
    }
}
