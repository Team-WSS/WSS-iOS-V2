//
//  DevicePushToken.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


public struct DevicePushToken: Equatable {
    public let token: String
    public let deviceID: String

    public init(token: String, deviceID: String) {
        self.token = token
        self.deviceID = deviceID
    }
}
