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
///
/// `Sendable`: 불변 `os.Logger`(그 자체로 Sendable) 하나만 보유하는 final class라 값처럼 안전하게
/// 공유된다. 공용 인스턴스들(`OSLogger.network` 등 static let)이 여러 스레드에서 쓰이므로 Sendable이어야 한다.
public final class OSLogger: Logger, Sendable {
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
    static let profile      = OSLogger(category: .profile)
    static let social       = OSLogger(category: .social)
    static let search       = OSLogger(category: .search)
    static let collection   = OSLogger(category: .collection)
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
    case profile
    case social
    case search
    case collection
}
