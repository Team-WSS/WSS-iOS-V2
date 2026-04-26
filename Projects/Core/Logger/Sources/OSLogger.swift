//
//  OSLogger.swift
//  Logger
//
//  Created by Seoyeon Choi on 3/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import os

/// OSLog 기반 Logger 구현체
public final class OSLogger: Logger {
    private let logger: os.Logger

    public init(subsystem: String = Bundle.main.bundleIdentifier ?? "kr.websoso.app",
                category: LogCategory) {
        self.logger = os.Logger(subsystem: subsystem, category: category.rawValue)
    }

    public func debug(_ message: String) {
        logger.debug("\(message, privacy: .public)")
    }

    public func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    public func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }
}

// MARK: - Shared Instances

public extension OSLogger {
    static let network      = OSLogger(category: .network)
    static let auth         = OSLogger(category: .auth)
    static let ui           = OSLogger(category: .ui)
    static let general      = OSLogger(category: .general)
    static let novel        = OSLogger(category: .novel)
    static let notification = OSLogger(category: .notification)
    static let feed         = OSLogger(category: .feed)
    static let recommendation = OSLogger(category: .recommendation)
    static let keyword      = OSLogger(category: .keyword)
    static let comment      = OSLogger(category: .comment)
}

// MARK: - LogCategory

public enum LogCategory: String {
    case network
    case auth
    case ui
    case general
    case novel
    case notification
    case feed
    case recommendation
    case keyword
    case comment
}
