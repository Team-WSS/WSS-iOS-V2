//
//  MockNovelNotificationSettingRepository.swift
//  NotificationDomain
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import NotificationDomain
import BaseDomain

public final class MockNovelNotificationSettingRepository: NovelNotificationSettingRepository {

    // MARK: - loadNotificationSetting

    public var loadedNovelID: NovelID?
    public var loadNotificationSettingCallCount = 0
    public var loadNotificationSettingResult: Result<NovelNotificationSetting, RepositoryError>?

    public func loadNotificationSetting(novelID: NovelID) async throws(RepositoryError) -> NovelNotificationSetting {
        loadNotificationSettingCallCount += 1
        loadedNovelID = novelID

        guard let loadNotificationSettingResult else {
            fatalError("loadNotificationSettingResult is not set")
        }

        switch loadNotificationSettingResult {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }

    // MARK: - updateNotificationSetting

    public var updatedNovelID: NovelID?
    public var updatedSetting: NovelNotificationSetting?
    public var updateNotificationSettingCallCount = 0
    public var updateNotificationSettingResult: Result<Void, RepositoryError>?

    public func updateNotificationSetting(
        novelID: NovelID,
        setting: NovelNotificationSetting
    ) async throws(RepositoryError) {
        updateNotificationSettingCallCount += 1
        updatedNovelID = novelID
        updatedSetting = setting

        if let updateNotificationSettingResult {
            switch updateNotificationSettingResult {
            case .success:
                return
            case .failure(let error):
                throw error
            }
        }
    }

    public init() {}
}
