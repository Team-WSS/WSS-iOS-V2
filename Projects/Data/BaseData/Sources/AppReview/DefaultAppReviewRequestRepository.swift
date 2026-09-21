//
//  DefaultAppReviewRequestRepository.swift
//  BaseData
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

/// 앱 리뷰 게이트 상태(참여 카운트·그 카운트의 버전·마지막 요청 버전)를 `UserDefaults`(AppStorage)에 저장하고,
/// 현재 앱 버전을 `Bundle`에서 읽어 제공하는 `AppReviewRequestRepository` 구현. 순수 저장소라 버전 리셋 등
/// 정책 판단은 하지 않는다(그건 `AppReviewRequestUseCase` 몫).
///
/// 네트워크가 없어(순수 로컬) `client`가 필요 없으므로 Factory 없이 App(DI)이 직접 조립한다 —
/// BaseData는 `factory-exclusivity`(규칙⑫)의 예외라 `UserDefaultsStorage`처럼 public 타입을 그대로 열어도 된다.
public struct DefaultAppReviewRequestRepository: AppReviewRequestRepository {

    private let appStorage: AppStorage

    /// 현재 앱 버전은 init에서 1회 읽어 고정한다 — `Bundle` 자체를 보유하지 않아 Sendable-safe.
    /// 읽기 패턴은 `NetworkingConfig`(plist 키 로드)와 동일.
    public let currentAppVersion: String

    public init(appStorage: AppStorage, bundle: Bundle = .main) {
        self.appStorage = appStorage
        self.currentAppVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
    }

    public var engagementCount: Int {
        appStorage.get(Self.countKey) ?? 0
    }

    public func setEngagementCount(_ count: Int) {
        appStorage.set(Self.countKey, count)
    }

    public var engagementCountVersion: String? {
        appStorage.get(Self.countVersionKey)
    }

    public func setEngagementCountVersion(_ version: String) {
        appStorage.set(Self.countVersionKey, version)
    }

    public var lastRequestedVersion: String? {
        appStorage.get(Self.lastRequestedVersionKey)
    }

    public func setLastRequestedVersion(_ version: String) {
        appStorage.set(Self.lastRequestedVersionKey, version)
    }

    // MARK: - Keys

    /// ⚠️ `Value` 타입(`Int`/`String`)을 저장/조회 값과 항상 일치시킬 것 —
    /// `UserDefaultsStorage`가 `as? V`라 타입이 어긋나면 조용히 nil(`StorageKey` 주의사항 참고).
    /// `StorageKey`는 `Sendable`이 아니라 `static let`으로 두면 concurrency 에러 → 매 접근 새로 만드는
    /// computed로 둔다(온보딩 힌트 repo가 인스턴스 키를 인라인 생성하는 것과 같은 이유).
    private static var countKey: StorageKey<Int> { StorageKey("appReview.engagementCount") }
    private static var countVersionKey: StorageKey<String> { StorageKey("appReview.engagementCountVersion") }
    private static var lastRequestedVersionKey: StorageKey<String> { StorageKey("appReview.lastRequestedVersion") }
}
