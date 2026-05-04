//
//  CacheError.swift
//  BaseData
//
//  Created by Seoyeon Choi on 5/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public enum CacheError: Error, CustomStringConvertible {
    case fileNotFound
    case decodingFailed
    case encodingFailed
    case writeFailed

    public var description: String {
        switch self {
        case .fileNotFound:
            return "캐시 파일이 존재하지 않음"
        case .decodingFailed:
            return "캐시 파일 디코딩 실패"
        case .encodingFailed:
            return "캐시 데이터 인코딩 실패"
        case .writeFailed:
            return "캐시 파일 저장 실패"
        }
    }
}
