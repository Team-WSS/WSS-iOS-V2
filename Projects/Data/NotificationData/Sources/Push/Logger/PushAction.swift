//
//  PushAction.swift
//  NotificationData
//
//  Created by Codex on 4/29/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

enum PushAction {
    case loadPreference
    case updatePreference
    case registerToken

    var name: String {
        switch self {
        case .loadPreference:
            return "loadPreference"
        case .updatePreference:
            return "updatePreference"
        case .registerToken:
            return "registerToken"
        }
    }
}
