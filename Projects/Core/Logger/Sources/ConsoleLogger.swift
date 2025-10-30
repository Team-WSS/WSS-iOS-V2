//
//  ConsoleLogger.swift
//  Logger
//
//  Created by YunhakLee on 10/31/25.
//

/// 콘솔 출력용 Logger 구현체
public final class ConsoleLogger: Logger {
    private let showDebug: Bool

    public init(showDebug: Bool = true) {
        self.showDebug = showDebug
    }

    public func debug(_ message: String) {
        #if DEBUG
        guard showDebug else { return }
        print("🟦 [DEBUG] \(message)")
        #endif
    }

    public func info(_ message: String) {
        print("🟩 [INFO] \(message)")
    }

    public func error(_ message: String) {
        print("🟥 [ERROR] \(message)")
    }
}
