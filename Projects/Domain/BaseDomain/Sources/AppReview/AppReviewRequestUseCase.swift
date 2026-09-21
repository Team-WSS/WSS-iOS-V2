//
//  AppReviewRequestUseCase.swift
//  BaseDomain
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// 앱스토어 평점 프롬프트를 **언제 띄울지** 판정하는 정책. 피드·감상평 등 여러 화면이 이 하나의 UseCase를
/// 공유해, 앱 전체 기준으로 게이팅한다("무분별 호출 금지").
///
/// 정책: 긍정 완료를 `recordEngagement()`로 누적하고, `shouldRequestReview()`가
/// **이번 앱 버전 누적 참여 ≥ 임계치 AND 이번 앱 버전에서 아직 미요청**일 때만 true. 실제 프롬프트를 띄운 뒤
/// `markReviewRequested()`로 현재 버전을 각인해 같은 버전 재요청을 막는다.
/// ⚠️ **참여 카운트는 앱 버전이 바뀌면 0부터 다시 센다**(누적이 아니라 버전별) — 그래야 임계치가 매 버전
/// 의미를 갖는다(누적이면 한 번 임계치를 넘긴 뒤엔 새 버전마다 첫 저장에 바로 떠 임계치가 사실상 죽는다).
/// (실제 다이얼로그 노출은 StoreKit이 연 3회·최근표시 억제로 하드캡을 별도로 건다.)
public protocol AppReviewRequestUseCase: Sendable {
    /// 긍정 완료(피드 작성/수정 성공, 감상평 저장 성공)를 1건 기록한다(앱 버전이 바뀌었으면 1부터 다시 시작).
    func recordEngagement()
    /// 지금 리뷰 프롬프트를 띄워도 되는지 판정한다.
    func shouldRequestReview() -> Bool
    /// 리뷰를 요청했음을 기록한다(이번 앱 버전 각인 → 같은 버전에선 다시 안 뜸).
    func markReviewRequested()
}

public final class DefaultAppReviewRequestUseCase: AppReviewRequestUseCase {

    private let repository: AppReviewRequestRepository
    /// 리뷰 요청 전 필요한 (이번 버전) 최소 누적 참여 수. 사용자가 앱에 대한 의견을 형성한 뒤에만 묻기 위한 값.
    private let threshold: Int

    public init(repository: AppReviewRequestRepository, threshold: Int = 3) {
        self.repository = repository
        self.threshold = threshold
    }

    public func recordEngagement() {
        let base = currentVersionEngagementCount()
        repository.setEngagementCount(base + 1)
        repository.setEngagementCountVersion(repository.currentAppVersion)
    }

    public func shouldRequestReview() -> Bool {
        currentVersionEngagementCount() >= threshold
        && repository.lastRequestedVersion != repository.currentAppVersion
    }

    public func markReviewRequested() {
        repository.setLastRequestedVersion(repository.currentAppVersion)
    }

    /// 저장된 카운트가 현재 앱 버전에서 쌓인 것이면 그 값을, 버전이 바뀌었으면 0을 반환한다(버전별 리셋).
    private func currentVersionEngagementCount() -> Int {
        repository.engagementCountVersion == repository.currentAppVersion ? repository.engagementCount : 0
    }
}
