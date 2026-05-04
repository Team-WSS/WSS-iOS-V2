//
//  NetworkingError+RepositoryError.swift
//  BaseData
//
//  Created by Wonsun Lee on 4/13/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Networking
import BaseDomain

/// HTTP 상태 코드 → RepositoryError 변환
public extension NetworkingError {
    func toRepositoryError() -> RepositoryError {
        switch self {
        case .invalidURL:
            return .unknown
        case .decoding:
            return .invalidData
        case .responseFailure(let code, _):
            switch code {
            case 401: return .authenticationRequired
            case 404:      return .notFound
            case 500...599: return .serverUnavailable
            default:       return .unknown
            }
        case .requiresReauthentication:
            return .authenticationRequired
        case .unknown:
            return .networkUnavailable
        }
    }
}
