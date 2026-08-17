//
//  UpdateNovelNotificationSettingUseCaseTests.swift
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

@Suite("UpdateNovelNotificationSettingUseCase")
struct UpdateNovelNotificationSettingUseCaseTests {

    @Test("작품 ID와 갱신할 알림 설정을 그대로 레포지토리에 전달한다")
    func updatesNotificationSetting() async throws {
        let repo = MockNovelNotificationSettingRepository()
        repo.updateNotificationSettingResult = .success(())

        let sut = DefaultUpdateNovelNotificationSettingUseCase(repository: repo)

        let novelID = NovelID(1)
        let setting = NovelNotificationSetting(
            isCompletionNotificationEnabled: true,
            isHiatusReturnNotificationEnabled: true
        )
        try await sut.execute(novelID: novelID, setting: setting)

        #expect(repo.updateNotificationSettingCallCount == 1)
        #expect(repo.updatedNovelID == novelID)
        #expect(repo.updatedSetting == setting)
    }

    @Test("갱신 중 레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockNovelNotificationSettingRepository()
        repo.updateNotificationSettingResult = .failure(.networkUnavailable)

        let sut = DefaultUpdateNovelNotificationSettingUseCase(repository: repo)

        let setting = NovelNotificationSetting(
            isCompletionNotificationEnabled: false,
            isHiatusReturnNotificationEnabled: false
        )

        await #expect(throws: RepositoryError.networkUnavailable) {
            try await sut.execute(novelID: NovelID(1), setting: setting)
        }

        #expect(repo.updateNotificationSettingCallCount == 1)
    }
}
