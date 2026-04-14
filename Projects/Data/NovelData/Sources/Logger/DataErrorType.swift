//
//  DataErrorType.swift
//  NovelData
//
//  Created by Seoyeon Choi on 4/12/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

/// Data 모듈 공통 에러 타입
public enum DataErrorType {
    case network
    case unknown
    
    public var text: String {
        switch self {
        case .network:  return "network"
        case .unknown:  return "unknown"
        }
    }
}
