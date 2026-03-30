//
//  RecommendationLogger.swift
//  RecommendationData
//
//  Created by Seoyeon Choi on 3/30/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Logger

public protocol RecommendationLogger {
    func logError(
        type: RecommendationErrorType,
        action: RecommendationAction,
        error: Error?
    )
}

public struct DefaultRecommendationLogger: RecommendationLogger {
    private let base: Logger

    public init(base: Logger) {
        self.base = base
    }

    public func logError(
        type: RecommendationErrorType,
        action: RecommendationAction,
        error: Error?
    ) {
        var message = "📦 [RecommendationData] \(action.text) \(type.text) error"
        if let error {
            message += ": \(error)"
        }
        base.error(message)
    }
}

public enum RecommendationAction {
    case load

    var text: String {
        switch self {
        case .load: return "load"
        }
    }
}

public enum RecommendationErrorType {
    case mapping, network, unknown

    var text: String {
        switch self {
        case .mapping: return "mapping"
        case .network: return "network"
        case .unknown: return "unknown"
        }
    }
}
