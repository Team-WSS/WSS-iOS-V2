//
//  DefaultOnboardingHintRepository.swift
//  BaseData
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

/// 온보딩 힌트 "봤음" 플래그를 `UserDefaults`(AppStorage)에 저장하는 `OnboardingHintRepository` 구현.
/// 힌트별로 키를 네임스페이스(`onboardingHint.<rawValue>`)해 `Bool`로 저장한다 — 미저장(첫 방문)이면
/// `get`이 nil → `hasSeen`이 false다.
///
/// 네트워크가 없어(순수 로컬) `client`가 필요 없으므로 Factory 없이 App(DI)이 직접 조립한다 —
/// BaseData는 `factory-exclusivity`(규칙⑫)의 예외(다른 Data가 직접 import하는 공용 토대)라
/// `UserDefaultsStorage`처럼 public 타입을 그대로 열어도 된다.
public struct DefaultOnboardingHintRepository: OnboardingHintRepository {

    private let appStorage: AppStorage

    public init(appStorage: AppStorage) {
        self.appStorage = appStorage
    }

    public func hasSeen(_ hint: OnboardingHint) -> Bool {
        appStorage.get(key(for: hint)) ?? false
    }

    public func markSeen(_ hint: OnboardingHint) {
        appStorage.set(key(for: hint), true)
    }

    /// 힌트별 저장 키. ⚠️ `Value`가 `Bool`이라 저장/조회 값도 항상 `Bool`이어야 한다
    /// (`UserDefaultsStorage`가 `as? V`라 타입이 어긋나면 조용히 nil — `StorageKey` 주의사항 참고).
    private func key(for hint: OnboardingHint) -> StorageKey<Bool> {
        StorageKey<Bool>("onboardingHint.\(hint.rawValue)")
    }
}
