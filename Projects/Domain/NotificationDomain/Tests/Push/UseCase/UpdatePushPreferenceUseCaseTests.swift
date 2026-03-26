//
//  UpdatePushPreferenceUseCaseTests.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import NotificationDomain
import NotificationDomainTesting
import BaseDomain

@Suite("UpdatePushPreferenceUseCase")
struct UpdatePushPreferenceUseCaseTests {

    private func makePreference() -> PushPreference {
        return PushPreference(isEnabled: true)
    }

    @Test("푸시 알림 수신 여부를 변경할 수 있다")
    func updatesPushPreferenceSuccessfully() async throws {
        let repo = MockPushSettingRepository()
        repo.updateResult = .success(())

        let sut = DefaultUpdatePushPreferenceUseCase(repository: repo)
        let pref = makePreference()

        try await sut.execute(pushPreference: pref)

        #expect(repo.updateCallCount == 1)
        #expect(repo.lastUpdatedPreference == pref)
    }

    @Test("레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockPushSettingRepository()
        repo.updateResult = .failure(.serverUnavailable)

        let sut = DefaultUpdatePushPreferenceUseCase(repository: repo)

        await #expect(throws: RepositoryError.serverUnavailable) {
            try await sut.execute(pushPreference: makePreference())
        }

        #expect(repo.updateCallCount == 1)
    }
}
