//
//  MappingError.swift
//  BaseData
//
//  Created by Wonsun Lee on 4/13/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// DTO → 도메인 enum 변환 실패 시 Mapper가 throw하는 공통 에러
public enum MappingError: Error, Equatable, CustomStringConvertible {
    case invalidConversion(type: String, value: String)
    case invalidPayload(reason: String)  // 각 모듈에서 payload 정의하여 String 타입의 description으로 전달

    public var description: String {
        switch self {
        case let .invalidConversion(type, value):
            return "❌ Failed to convert '\(value)' to \(type)"
        case let .invalidPayload(reason):
            return "❌ Invalid payload: \(reason)"
        }
    }
}
