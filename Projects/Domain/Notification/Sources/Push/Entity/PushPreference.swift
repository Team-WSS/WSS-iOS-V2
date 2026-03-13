//
//  PushPreference.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

public struct PushPreference: Equatable {
    public let isEnabled: Bool
    public init(isEnabled: Bool) { self.isEnabled = isEnabled }
}
