//
//  NovelLogger.swift
//  NovelData
//
//  Created by Seoyeon Choi on 4/12/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Logger

public protocol NovelLogger {
    func logError(
        type: DataErrorType,
        action: NovelAction,
        error: Error?
    )
}

public struct DefaultNovelLogger: NovelLogger {
    private let base: Logger
    
    public init(base: Logger) {
        self.base = base
    }
    
    public func logError(
        type: DataErrorType,
        action: NovelAction,
        error: Error?
    ) {
        var message = "[NovelData] \(action.text) \(type.text) error"
        if let error {
            message += ": \(error)"
        }
        
        base.error(message)
    }
}

public enum NovelAction {
    case fetchNovel
    case addInterest
    case removeInterest
    case searchByText
    case searchByFilter
    case fetchMyLibrary
    case fetchUserLibrary
    case fetchRegisteredStats
    
    var text: String {
        switch self {
        case .fetchNovel:           return "작품 정보 조회"
        case .addInterest:          return "관심 등록"
        case .removeInterest:       return "관심 해제"
        case .searchByText:         return "텍스트 검색"
        case .searchByFilter:       return "필터 검색"
        case .fetchMyLibrary:       return "내 서재 조회"
        case .fetchUserLibrary:     return "유저 서재 조회"
        case .fetchRegisteredStats: return "등록 작품 통계 조회"
        }
    }
}
