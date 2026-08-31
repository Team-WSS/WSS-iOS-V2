//
//  OnboardingHintUseCaseTests.swift
//  BaseDomain
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

@testable import BaseDomain
import BaseDomainTesting

@Suite("온보딩 힌트 UseCase")
struct OnboardingHintUseCaseTests {

    @Test("이미 본 힌트는 hasSeen이 true다.")
    func returnsTrueWhenSeen() {
        let mock = MockOnboardingHintRepository(seenHints: [.novelDetailReview])
        let usecase = DefaultOnboardingHintUseCase(repository: mock)

        #expect(usecase.hasSeen(.novelDetailReview) == true)
    }

    @Test("아직 안 본 힌트는 hasSeen이 false다.")
    func returnsFalseWhenUnseen() {
        let mock = MockOnboardingHintRepository()
        let usecase = DefaultOnboardingHintUseCase(repository: mock)

        #expect(usecase.hasSeen(.novelDetailReview) == false)
    }

    @Test("markSeen은 저장소에 그 힌트를 봤음으로 위임하고, 이후 hasSeen이 true가 된다.")
    func markSeenDelegatesAndPersists() {
        let mock = MockOnboardingHintRepository()
        let usecase = DefaultOnboardingHintUseCase(repository: mock)

        usecase.markSeen(.novelDetailReview)

        #expect(mock.markSeenCalls == [.novelDetailReview])
        #expect(usecase.hasSeen(.novelDetailReview) == true)
    }
}
