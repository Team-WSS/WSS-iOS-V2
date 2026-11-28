//
//  AppReviewRequestUseCaseTests.swift
//  BaseDomain
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

import BaseDomain
import BaseDomainTesting

@Suite("앱 리뷰 요청")
struct AppReviewRequestUseCaseTests {

    @Test("참여가 2번뿐이면 리뷰를 요청하지 않는다")
    func twoEngagementsAreNotEnough() {
        let useCase = makeUseCase(MockAppReviewRequestRepository(engagementCount: 2))

        #expect(useCase.shouldRequestReview() == false)
    }

    @Test("참여가 3번이 되면 리뷰를 요청한다")
    func threeEngagementsRequestReview() {
        let useCase = makeUseCase(MockAppReviewRequestRepository(engagementCount: 3))

        #expect(useCase.shouldRequestReview() == true)
    }

    @Test("이번 버전에 이미 리뷰를 요청했으면 다시 요청하지 않는다")
    func alreadyRequestedThisVersion() {
        let repository = MockAppReviewRequestRepository(engagementCount: 3, lastRequestedVersion: "1.0.0")

        let useCase = makeUseCase(repository)

        #expect(useCase.shouldRequestReview() == false)
    }

    @Test("리뷰를 요청했다고 기록하면 이번 버전에서는 다시 요청하지 않는다")
    func markingRequestStopsFurtherRequests() {
        let useCase = makeUseCase(MockAppReviewRequestRepository(engagementCount: 3))

        useCase.markReviewRequested()

        #expect(useCase.shouldRequestReview() == false)
    }

    @Test("버전이 바뀌면 지난 버전의 참여는 세지 않는다")
    func previousVersionEngagementsDoNotCount() {
        let useCase = makeUseCase(previousVersionRepository(lastRequestedVersion: nil))

        #expect(useCase.shouldRequestReview() == false)
    }

    @Test("버전이 바뀐 뒤 참여를 기록하면 처음부터 다시 센다")
    func newVersionCountsFromStart() {
        let useCase = makeUseCase(previousVersionRepository(lastRequestedVersion: nil))

        record(useCase, times: 2)

        #expect(useCase.shouldRequestReview() == false)
    }

    @Test("새 버전에서 다시 3번 참여하면 지난 버전에 요청했어도 다시 요청한다")
    func newVersionCanRequestAgain() {
        let useCase = makeUseCase(previousVersionRepository(lastRequestedVersion: "1.0.0"))

        record(useCase, times: 3)

        #expect(useCase.shouldRequestReview() == true)
    }

    // MARK: - Helpers

    /// 기준 횟수는 기본값(3번)을 그대로 쓴다 — 기본값도 명세다.
    private func makeUseCase(_ repository: MockAppReviewRequestRepository) -> DefaultAppReviewRequestUseCase {
        DefaultAppReviewRequestUseCase(repository: repository)
    }

    /// 지난 버전(1.0.0)에서 참여를 5번 쌓고, 지금은 1.1.0인 저장소.
    private func previousVersionRepository(lastRequestedVersion: String?) -> MockAppReviewRequestRepository {
        MockAppReviewRequestRepository(
            engagementCount: 5,
            engagementCountVersion: "1.0.0",
            lastRequestedVersion: lastRequestedVersion,
            currentAppVersion: "1.1.0"
        )
    }

    private func record(_ useCase: DefaultAppReviewRequestUseCase, times: Int) {
        for _ in 0..<times { useCase.recordEngagement() }
    }
}
