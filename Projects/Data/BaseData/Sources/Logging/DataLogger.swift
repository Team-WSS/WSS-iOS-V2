//
//  DataLogger.swift
//  BaseData
//
//  Created by Wonsun Lee on 4/13/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Logger
import Networking

/// Data 레이어 Repository용 구조화 로거.
public struct DataLogger {
    private let moduleName: String
    private let underlying: Logger?

    public init(moduleName: String, underlying: Logger? = nil) {
        self.moduleName = moduleName
        self.underlying = underlying
    }

    /// NetworkingError catch 블록에서 사용
    public func logNetworkError(action: String, error: NetworkingError) {
        underlying?.error("❌ [\(moduleName)] \(action) network error: \(error)")
    }

    /// MappingError catch 블록에서 사용
    public func logMappingError(action: String, error: MappingError) {
        underlying?.error("❌ [\(moduleName)] \(action) mapping error: \(error)")
    }

    /// CacheError catch 블록에서 사용
    public func logCacheError(action: String, error: CacheError) {
        underlying?.error("❌ [\(moduleName)] \(action) cache error: \(error)")
    }

    /// 나머지 catch 블록에서 사용
    public func logUnknownError(action: String, error: Error) {
        underlying?.error("❌ [\(moduleName)] \(action) unknown error: \(error)")
    }

    public func logSuccess(action: String) {
        underlying?.debug("✅ [\(moduleName)] \(action) succeeded")
    }
}
