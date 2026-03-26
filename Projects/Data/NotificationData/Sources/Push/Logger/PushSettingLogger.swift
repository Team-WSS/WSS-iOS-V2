//
//  PushSettingLogger.swift
//  NotificationData
//
//  Created by YunhakLee on 3/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


//
//  PushSettingLogger.swift
//  NotificationData
//

import Logger

public protocol PushSettingLogger {
    func logError(
        type: PushSettingErrorType,
        action: PushSettingAction,
        error: Error?
    )
}

public struct DefaultPushSettingLogger: PushSettingLogger {
    private let base: Logger
    
    public init(base: Logger) {
        self.base = base
    }
    
    public func logError(
        type: PushSettingErrorType,
        action: PushSettingAction,
        error: Error?
    ) {
        var message = "📦 [PushSettingData] \(action.text) \(type.text) error"
        if let error {
            message += ": \(error)"
        }
        
        base.error(message)
    }
}

public enum PushSettingErrorType {
    case network
    case unknown
    
    var text: String {
        switch self {
        case .network: return "network"
        case .unknown: return "unknown"
        }
    }
}

public enum PushSettingAction {
    case loadPreference
    case updatePreference
    case registerToken
    
    var text: String {
        switch self {
        case .loadPreference:   return "loadPreference"
        case .updatePreference: return "updatePreference"
        case .registerToken:    return "registerToken"
        }
    }
}
