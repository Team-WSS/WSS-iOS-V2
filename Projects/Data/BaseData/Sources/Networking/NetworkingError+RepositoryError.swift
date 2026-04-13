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
/// 모든 Data 모듈이 이 extension을 공유하여 에러 매핑 정책을 일관되게 유지.
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
        case .unknown:
            return .networkUnavailable
        }
    }
}
