//
//  DefaultPushRepository.swift
//  NotificationData
//
//  Created by YunhakLee on 3/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import NotificationDomain
import BaseDomain
import Logger
import Networking

public struct DefaultPushSettingRepository: PushSettingRepository {
    private let service: PushSettingService
    private let logger: PushSettingLogger?
    
    init(
        pushSettingService: PushSettingService,
        logger: PushSettingLogger?
    ) {
        self.service = pushSettingService
        self.logger = logger
    }
    
    public func loadPushPreference() async throws(RepositoryError) -> PushPreference {
        do {
            let response = try await service.getPushNotificationSetting()
            return PushSettingMapper.pushPreference(from: response)
        } catch let error as NetworkingError {
            logger?.logError(type: .network, action: .loadPreference, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logError(type: .unknown, action: .loadPreference, error: error)
            throw .unknown
        }
    }
    
    public func updatePushPreference(_ preference: PushPreference) async throws(RepositoryError) {
        do {
            let request = PushSettingMapper.pushNotificationSettingRequest(from: preference)
            try await service.postPushNotificationSetting(request)
        } catch let error as NetworkingError {
            logger?.logError(type: .network, action: .updatePreference, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logError(type: .unknown, action: .updatePreference, error: error)
            throw .unknown
        }
    }
    
    public func registerDeviceToken(_ token: DevicePushToken) async throws(RepositoryError) {
        do {
            let request = PushSettingMapper.fcmTokenRequest(from: token)
            try await service.postFCMToken(request)
        } catch let error as NetworkingError {
            logger?.logError(type: .network, action: .registerToken, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logError(type: .unknown, action: .registerToken, error: error)
            throw .unknown
        }
    }
}
