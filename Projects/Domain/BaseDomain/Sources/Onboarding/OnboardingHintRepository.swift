//
//  OnboardingHintRepository.swift
//  BaseDomain
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// 1회성 온보딩 힌트의 "봤음" 플래그를 로컬에 저장/조회하는 계약.
///
/// ⚠️ **동기·비-throwing이다**(다른 Repository의 `async throws`와 다르다) — 순수 로컬(서버·userID 무관)이고,
/// 화면이 뜨는 첫 프레임에 힌트를 띄울지 **동기로** 판정해야 깜빡임 없이 표시/생략을 정할 수 있어서다.
/// 구현은 `BaseData`의 `DefaultOnboardingHintRepository`(UserDefaults).
public protocol OnboardingHintRepository: Sendable {
    /// 해당 힌트를 이미 봤으면 true. 저장된 값이 없으면(첫 방문) false.
    func hasSeen(_ hint: OnboardingHint) -> Bool
    /// 해당 힌트를 봤음으로 기록한다(이후 `hasSeen`이 true).
    func markSeen(_ hint: OnboardingHint)
}
