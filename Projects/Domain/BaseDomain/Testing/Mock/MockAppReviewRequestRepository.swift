//
//  MockAppReviewRequestRepository.swift
//  BaseDomain
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

/// 테스트용 인메모리 앱 리뷰 게이트 저장소. 초기 카운트·그 카운트의 버전·마지막 요청 버전·현재 버전을
/// 주입할 수 있고, set 호출로 상태가 바뀌어 UseCase 정책(임계치·버전 리셋·버전 게이트)을 그대로 검증할 수 있다.
/// `engagementCountVersion` 기본값을 `currentAppVersion` 기본값과 같게 둬(둘 다 "1.0.0"), 버전을 명시하지 않은
/// 테스트에선 저장된 카운트가 "현재 버전 것"으로 취급된다.
public final class MockAppReviewRequestRepository: AppReviewRequestRepository {

    public var engagementCount: Int
    public var engagementCountVersion: String?
    public var lastRequestedVersion: String?
    public var currentAppVersion: String

    public init(
        engagementCount: Int = 0,
        engagementCountVersion: String? = "1.0.0",
        lastRequestedVersion: String? = nil,
        currentAppVersion: String = "1.0.0"
    ) {
        self.engagementCount = engagementCount
        self.engagementCountVersion = engagementCountVersion
        self.lastRequestedVersion = lastRequestedVersion
        self.currentAppVersion = currentAppVersion
    }

    public func setEngagementCount(_ count: Int) {
        engagementCount = count
    }

    public func setEngagementCountVersion(_ version: String) {
        engagementCountVersion = version
    }

    public func setLastRequestedVersion(_ version: String) {
        lastRequestedVersion = version
    }
}
