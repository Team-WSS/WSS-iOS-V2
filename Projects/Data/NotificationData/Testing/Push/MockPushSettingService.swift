//
//  MockPushSettingService.swift
//  NotificationData
//
//  Created by YunhakLee on 3/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


@testable import NotificationData

final class MockPushSettingService: PushSettingService {
    var getPushNotificationSettingResult: Result<PushNotificationSettingResponse, Error>!
    var postPushNotificationSettingResult: Result<Void, Error> = .success(())
    var postFCMTokenResult: Result<Void, Error> = .success(())

    private(set) var postedPushNotificationSettingRequest: PushNotificationSettingRequest?
    private(set) var postedFCMTokenRequest: FCMTokenRequest?

    func getPushNotificationSetting() async throws -> PushNotificationSettingResponse {
        try getPushNotificationSettingResult.get()
    }

    func postPushNotificationSetting(_ request: PushNotificationSettingRequest) async throws {
        postedPushNotificationSettingRequest = request
        _ = try postPushNotificationSettingResult.get()
    }

    func postFCMToken(_ request: FCMTokenRequest) async throws {
        postedFCMTokenRequest = request
        _ = try postFCMTokenResult.get()
    }
}
