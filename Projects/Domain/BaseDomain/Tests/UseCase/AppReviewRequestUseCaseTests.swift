//
//  AppReviewRequestUseCaseTests.swift
//  BaseDomain
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

@testable import BaseDomain
import BaseDomainTesting

@Suite("앱 리뷰 요청 게이팅 UseCase")
struct AppReviewRequestUseCaseTests {

    @Test("누적 참여가 임계치 미만이면 요청하지 않는다.")
    func belowThreshold_returnsFalse() {
        let mock = MockAppReviewRequestRepository(engagementCount: 2, currentAppVersion: "1.0.0")
        let usecase = DefaultAppReviewRequestUseCase(repository: mock, threshold: 3)

        #expect(usecase.shouldRequestReview() == false)
    }

    @Test("임계치를 채웠어도 이번 버전에서 이미 요청했으면 다시 요청하지 않는다.")
    func atThreshold_sameVersion_returnsFalse() {
        let mock = MockAppReviewRequestRepository(
            engagementCount: 3,
            lastRequestedVersion: "1.0.0",
            currentAppVersion: "1.0.0"
        )
        let usecase = DefaultAppReviewRequestUseCase(repository: mock, threshold: 3)

        #expect(usecase.shouldRequestReview() == false)
    }

    @Test("임계치를 채웠고 이번 버전에서 아직 요청 전이면 요청한다.")
    func atThreshold_newVersion_returnsTrue() {
        let mock = MockAppReviewRequestRepository(
            engagementCount: 3,
            lastRequestedVersion: "0.9.0",
            currentAppVersion: "1.0.0"
        )
        let usecase = DefaultAppReviewRequestUseCase(repository: mock, threshold: 3)

        #expect(usecase.shouldRequestReview() == true)
    }

    @Test("recordEngagement는 누적 참여 수를 1씩 올린다.")
    func recordEngagement_increments() {
        let mock = MockAppReviewRequestRepository(engagementCount: 0)
        let usecase = DefaultAppReviewRequestUseCase(repository: mock)

        usecase.recordEngagement()
        usecase.recordEngagement()

        #expect(mock.engagementCount == 2)
    }

    @Test("markReviewRequested는 현재 앱 버전을 마지막 요청 버전으로 각인한다.")
    func markReviewRequested_persistsCurrentVersion() {
        let mock = MockAppReviewRequestRepository(currentAppVersion: "2.1.0")
        let usecase = DefaultAppReviewRequestUseCase(repository: mock)

        usecase.markReviewRequested()

        #expect(mock.lastRequestedVersion == "2.1.0")
    }

    @Test("앱 버전이 바뀐 뒤 recordEngagement는 이전 버전 카운트를 버리고 1부터 다시 센다.")
    func recordEngagement_onNewVersion_resetsCount() {
        let mock = MockAppReviewRequestRepository(
            engagementCount: 5,
            engagementCountVersion: "0.9.0",
            currentAppVersion: "1.0.0"
        )
        let usecase = DefaultAppReviewRequestUseCase(repository: mock)

        usecase.recordEngagement()

        #expect(mock.engagementCount == 1)
        #expect(mock.engagementCountVersion == "1.0.0")
    }

    @Test("이전 버전에서 쌓인 카운트는 임계치 판정에서 무효다(버전이 바뀌면 0으로 본다).")
    func shouldRequestReview_ignoresOldVersionCount() {
        let mock = MockAppReviewRequestRepository(
            engagementCount: 5,
            engagementCountVersion: "0.9.0",
            lastRequestedVersion: nil,
            currentAppVersion: "1.0.0"
        )
        let usecase = DefaultAppReviewRequestUseCase(repository: mock, threshold: 3)

        #expect(usecase.shouldRequestReview() == false)
    }
}
