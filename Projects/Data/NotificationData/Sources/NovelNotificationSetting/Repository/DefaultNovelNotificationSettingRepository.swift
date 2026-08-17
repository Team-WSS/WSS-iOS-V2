//
//  DefaultNovelNotificationSettingRepository.swift
//  NotificationData
//
//  Created by Guryss on 8/17/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import NotificationDomain
import BaseDomain
import BaseData
import Networking

public struct DefaultNovelNotificationSettingRepository: NovelNotificationSettingRepository {
    private let service: NovelNotificationSettingService
    private let logger: DataLogger?

    init(
        novelNotificationSettingService: NovelNotificationSettingService,
        logger: DataLogger?
    ) {
        self.service = novelNotificationSettingService
        self.logger = logger
    }

    public func loadNotificationSetting(novelID: NovelID) async throws(RepositoryError) -> NovelNotificationSetting {
        let action = NovelNotificationSettingAction.loadSetting

        do {
            let response = try await service.getNotificationSetting(novelID: novelID.value)
            let result = NovelNotificationSettingMapper.setting(from: response)
            logger?.logSuccess(action: action.name)
            return result
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func updateNotificationSetting(
        novelID: NovelID,
        setting: NovelNotificationSetting
    ) async throws(RepositoryError) {
        let action = NovelNotificationSettingAction.updateSetting

        do {
            let request = NovelNotificationSettingMapper.request(from: setting)
            try await service.putNotificationSetting(novelID: novelID.value, request: request)
            logger?.logSuccess(action: action.name)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }
}
