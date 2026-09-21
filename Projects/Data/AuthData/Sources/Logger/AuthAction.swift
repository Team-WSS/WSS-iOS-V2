//
//  AuthAction.swift
//  AuthData
//
//  Created by Codex on 4/29/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

enum AuthAction {
    case login
    case logout
    case withdraw
    case syncAppleCredential
    case refreshSession

    var name: String {
        switch self {
        case .login:
            return "login"
        case .logout:
            return "logout"
        case .withdraw:
            return "withdraw"
        case .syncAppleCredential:
            return "syncAppleCredential"
        case .refreshSession:
            return "refreshSession"
        }
    }
}
