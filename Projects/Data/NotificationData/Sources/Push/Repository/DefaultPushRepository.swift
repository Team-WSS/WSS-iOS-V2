//
//  DefaultPushRepository.swift
//  NotificationData
//
//  Created by YunhakLee on 3/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import NotificationDomain
import BaseDomain
import BaseData
import Networking

public struct DefaultPushSettingRepository: PushSettingRepository {
    private let service: PushSettingService
    private let logger: DataLogger?

    init(
        pushSettingService: PushSettingService,
        logger: DataLogger?
    ) {
        self.service = pushSettingService
        self.logger = logger
    }

    public func loadPushPreference() async throws(RepositoryError) -> PushPreference {
        let action = PushAction.loadPreference

        do {
            let response = try await service.getPushNotificationSetting()
            let result = PushSettingMapper.pushPreference(from: response)
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

    public func updatePushPreference(_ preference: PushPreference) async throws(RepositoryError) {
        let action = PushAction.updatePreference

        do {
            let request = PushSettingMapper.pushNotificationSettingRequest(from: preference)
            try await service.postPushNotificationSetting(request)
            logger?.logSuccess(action: action.name)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }

    public func registerDeviceToken(_ token: DevicePushToken) async throws(RepositoryError) {
        let action = PushAction.registerToken

        do {
            let request = PushSettingMapper.fcmTokenRequest(from: token)
            try await service.postFCMToken(request)
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
