//
//  AppReviewRequestRepository.swift
//  BaseDomain
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// 앱스토어 평점 요청의 게이팅 상태(참여 카운트·그 카운트가 쌓인 버전·마지막 요청 버전)를 로컬에
/// 저장/조회하고, 판정에 필요한 현재 앱 버전을 제공하는 **순수 저장소** 계약. 버전 리셋 등 정책 판단은
/// 저장소가 아니라 `AppReviewRequestUseCase`가 한다(저장소는 값만 보관).
///
/// ⚠️ **동기·비-throwing이다**(다른 Repository의 `async throws`와 다르다) — 순수 로컬(서버·userID 무관)이고,
/// 저장 성공 직후 "지금 물어볼까?"를 **동기로** 판정해야 하기 때문이다. 구현은 `BaseData`의
/// `DefaultAppReviewRequestRepository`(UserDefaults + Bundle 버전).
public protocol AppReviewRequestRepository: Sendable {
    /// 저장된 긍정 완료 누적 횟수(원값). "현재 버전 기준"으로 유효한지는 `engagementCountVersion`과
    /// 함께 UseCase가 판단한다 — 버전이 다르면 옛 버전 카운트라 UseCase가 0으로 취급한다.
    var engagementCount: Int { get }
    func setEngagementCount(_ count: Int)

    /// `engagementCount`가 쌓인 앱 버전. 현재 앱 버전과 다르면 그 카운트는 이전 버전 것.
    var engagementCountVersion: String? { get }
    func setEngagementCountVersion(_ version: String)

    /// 마지막으로 리뷰를 요청했던 앱 버전. 아직 요청한 적 없으면 nil.
    var lastRequestedVersion: String? { get }
    func setLastRequestedVersion(_ version: String)

    /// 현재 앱 버전(`CFBundleShortVersionString`). 버전 게이트·카운트 리셋 판정의 기준값.
    var currentAppVersion: String { get }
}
