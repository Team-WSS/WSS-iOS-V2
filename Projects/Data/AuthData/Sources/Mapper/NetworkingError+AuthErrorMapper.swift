//
//  AuthErrorMapper.swift
//  AuthData
//
//  Created by YunhakLee on 4/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Networking
import AuthDomain

extension NetworkingError {
    func toAuthError() -> AuthError {
        switch self {
        case .invalidURL, .requiresReauthentication:
            return .unknown
        case .decoding:
            return .invalidData
        case .responseFailure(let code, _):
            switch code {
            case 400...499: return .invalidCredential
            case 500...599: return .providerUnavailable
            default:        return .unknown
            }
        case .unknown:
            return .networkUnavailable
        }
    }
}
