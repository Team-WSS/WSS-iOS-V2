//
//  LoadPushPreferenceUseCaseTests.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import NotificationDomain
import NotificationDomainTesting
import BaseDomain

@Suite("LoadPushPreferenceUseCase")
struct LoadPushPreferenceUseCaseTests {

    private func makePreference() -> PushPreference {
        return PushPreference(isEnabled: false)
    }

    @Test("푸시 알림 수신 여부를 조회할 수 있다")
    func loadsPushPreferenceSuccessfully() async throws {
        let repo = MockPushSettingRepository()
        let expected = makePreference()
        repo.loadResult = .success(expected)

        let sut = DefaultLoadPushPreferenceUseCase(repository: repo)

        let result = try await sut.execute()

        #expect(repo.loadCallCount == 1)
        #expect(result == expected)
    }

    @Test("조회 중 레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockPushSettingRepository()
        repo.loadResult = .failure(.networkUnavailable)

        let sut = DefaultLoadPushPreferenceUseCase(repository: repo)

        await #expect(throws: RepositoryError.networkUnavailable) {
            _ = try await sut.execute()
        }

        #expect(repo.loadCallCount == 1)
    }
}
