//
//  NovelReviewLogger.swift
//  NovelReviewData
//
//  Created by YunhakLee on 3/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Logger

public enum NovelReviewAction {
    case load, post, put, delete
    
    var text: String {
        switch self {
        case .load:     return "load"
        case .post:     return "post"
        case .put:      return "put"
        case .delete:   return "delete"
        }
    }
}

public enum NovelReviewErrorType {
    case mapping, network, unknown
    
    var text: String {
        switch self {
        case .mapping: return "mapping"
        case .network: return "network"
        case .unknown: return "unknown"
        }
    }
}

public protocol NovelReviewLogger {
    func logError(
        type: NovelReviewErrorType,
        action: NovelReviewAction,
        error: Error?
    )
}

public struct DefaultNovelReviewLogger: NovelReviewLogger {
    private let base: Logger
    
    public init(
        base: Logger
    ) {
        self.base = base
    }
    
    public func logError(
        type: NovelReviewErrorType,
        action: NovelReviewAction,
        error: Error?
    ) {
        var message = "📦 [NovelReviewData] \(action.text) \(type.text) error"
        if let error {
            message += ": \(error)"
        }
        
        base.error(message)
    }
}
