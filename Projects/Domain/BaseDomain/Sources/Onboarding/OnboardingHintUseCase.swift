//
//  OnboardingHintUseCase.swift
//  BaseDomain
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// 온보딩 힌트 표시 여부를 판정(`hasSeen`)하고 봤음을 기록(`markSeen`)한다.
/// 여러 화면이 각자의 `OnboardingHint` 케이스로 **이 하나의 UseCase를 공유**한다.
///
/// Repository와 메서드가 1:1이라 얇지만, Feature는 Repository가 아니라 UseCase에 의존한다는 레이어 관례를
/// 지키려 둔다(다른 Feature 의존과 형태를 맞춤). 동기·비-throwing 계약은 Repository와 동일(이유는 그쪽 참고).
public protocol OnboardingHintUseCase: Sendable {
    func hasSeen(_ hint: OnboardingHint) -> Bool
    func markSeen(_ hint: OnboardingHint)
}

public final class DefaultOnboardingHintUseCase: OnboardingHintUseCase {

    private let repository: OnboardingHintRepository

    public init(repository: OnboardingHintRepository) {
        self.repository = repository
    }

    public func hasSeen(_ hint: OnboardingHint) -> Bool {
        repository.hasSeen(hint)
    }

    public func markSeen(_ hint: OnboardingHint) {
        repository.markSeen(hint)
    }
}
