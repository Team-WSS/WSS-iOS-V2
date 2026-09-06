//
//  NetworkingError+RepositoryError.swift
//  BaseData
//
//  Created by Wonsun Lee on 4/13/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import Networking
import BaseDomain

/// HTTP 상태 코드 → RepositoryError 변환
public extension NetworkingError {
    func toRepositoryError() -> RepositoryError {
        switch self {
        case .invalidURL:
            return .unknown
        case .decoding, .requestEncodingFailed:
            return .invalidData
        case .responseFailure(let code, _):
            switch code {
            case 401:           return .authenticationRequired
            case 403:           return .forbidden
            case 404:           return .notFound
            case 500...599:     return .serverUnavailable
            default:            return .unknown
            }
        case .requiresReauthentication:
            return .authenticationRequired
        case .unknown(let error):
            // 응답조차 못 받은 통신 실패 중 "진짜 연결 없음"(오프라인)만 networkUnavailable로 가른다.
            // 타임아웃·DNS 실패·취소 등 나머지는 unknown(재시도 가능한 일반 오류) — 화면이 "인터넷 연결
            // 확인" 대신 "일시적 오류" 문구를 내야 정확하다. (URLError 검사는 도메인 무관한 Foundation
            // 심볼이라 Core가 아닌 이 변환 지점 몫 — Core는 도메인을 모른다는 원칙.)
            if let urlError = error as? URLError,
               urlError.code == .notConnectedToInternet || urlError.code == .networkConnectionLost {
                return .networkUnavailable
            }
            return .unknown
        }
    }
}
