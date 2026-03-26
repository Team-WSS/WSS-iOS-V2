//
//  PushSettingMapper.swift
//  NotificationData
//
//  Created by YunhakLee on 3/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import NotificationDomain
import BaseDomain

enum PushSettingMapper {
    static func pushPreference(
        from response: PushNotificationSettingResponse
    ) -> PushPreference {
        return PushPreference(isEnabled: response.isPushEnabled)
    }
    
    static func pushNotificationSettingRequest(
        from preference: PushPreference
    ) -> PushNotificationSettingRequest {
        return PushNotificationSettingRequest(isPushEnabled: preference.isEnabled)
    }
    
    static func fcmTokenRequest(
        from pushToken: DevicePushToken
    ) -> FCMTokenRequest {
        return FCMTokenRequest(fcmToken: pushToken.token, deviceIdentifier: pushToken.deviceID)
    }
}
