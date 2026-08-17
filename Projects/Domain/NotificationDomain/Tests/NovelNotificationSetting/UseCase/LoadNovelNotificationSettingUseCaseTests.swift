//
//  LoadNovelNotificationSettingUseCaseTests.swift
//  NotificationDomain
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

@testable import NotificationDomain
import NotificationDomainTesting
import BaseDomain

@Suite("LoadNovelNotificationSettingUseCase")
struct LoadNovelNotificationSettingUseCaseTests {

    @Test("작품 ID로 완결·휴재복귀 알림 설정을 조회한다")
    func loadsNotificationSetting() async throws {
        let repo = MockNovelNotificationSettingRepository()
        let expected = NovelNotificationSetting(
            isCompletionNotificationEnabled: true,
            isHiatusReturnNotificationEnabled: false
        )
        repo.loadNotificationSettingResult = .success(expected)

        let sut = DefaultLoadNovelNotificationSettingUseCase(repository: repo)

        let novelID = NovelID(1)
        let result = try await sut.execute(novelID: novelID)

        #expect(result == expected)
        #expect(repo.loadNotificationSettingCallCount == 1)
        #expect(repo.loadedNovelID == novelID)
    }

    @Test("조회 중 레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockNovelNotificationSettingRepository()
        repo.loadNotificationSettingResult = .failure(.networkUnavailable)

        let sut = DefaultLoadNovelNotificationSettingUseCase(repository: repo)

        await #expect(throws: RepositoryError.networkUnavailable) {
            _ = try await sut.execute(novelID: NovelID(1))
        }

        #expect(repo.loadNotificationSettingCallCount == 1)
    }
}
