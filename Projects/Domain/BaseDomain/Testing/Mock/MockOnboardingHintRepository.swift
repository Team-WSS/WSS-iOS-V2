//
//  MockOnboardingHintRepository.swift
//  BaseDomain
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

/// 테스트용 인메모리 온보딩 힌트 저장소. 초기 "봤음" 집합을 주입할 수 있고, `markSeen` 호출 이력을 노출한다.
public final class MockOnboardingHintRepository: OnboardingHintRepository {

    public var seenHints: Set<OnboardingHint>
    public private(set) var markSeenCalls: [OnboardingHint] = []

    public init(seenHints: Set<OnboardingHint> = []) {
        self.seenHints = seenHints
    }

    public func hasSeen(_ hint: OnboardingHint) -> Bool {
        seenHints.contains(hint)
    }

    public func markSeen(_ hint: OnboardingHint) {
        markSeenCalls.append(hint)
        seenHints.insert(hint)
    }
}
