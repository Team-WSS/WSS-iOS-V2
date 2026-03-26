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
    private let pushSettingService: PushSettingService
    
    init(pushSettingService: PushSettingService) {
        self.pushSettingService = pushSettingService
    }
    
    public func loadPushPreference() async throws(RepositoryError) -> PushPreference {
        do {
            let response = try await pushSettingService.getPushNotificationSetting()
            return PushSettingMapper.pushPreference(from: response)
        } catch let error as NetworkingError {
            throw error.toRepositoryError()
        } catch {
            throw .unknown
        }
    }
    
    public func updatePushPreference(_ preference: PushPreference) async throws(RepositoryError) {
        do {
            let request = PushSettingMapper.pushNotificationSettingRequest(from: preference)
            try await pushSettingService.postPushNotificationSetting(request)
        } catch let error as NetworkingError {
            throw error.toRepositoryError()
        } catch {
            throw .unknown
        }
    }
    
    public func registerDeviceToken(_ token: DevicePushToken) async throws(RepositoryError) {
        do {
            let request = PushSettingMapper.fcmTokenRequest(from: token)
            try await pushSettingService.postFCMToken(request)
        } catch let error as NetworkingError {
            throw error.toRepositoryError()
        } catch {
            throw .unknown
        }
    }
}
