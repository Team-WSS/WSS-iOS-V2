import Logger

public final class MockLogger: Logger {
    public private(set) var debugMessages: [String] = []
    public private(set) var infoMessages: [String] = []
    public private(set) var errorMessages: [String] = []

    public init() {}

    public func debug(_ message: String) {
        debugMessages.append(message)
    }

    public func info(_ message: String) {
        infoMessages.append(message)
    }

    public func error(_ message: String) {
        errorMessages.append(message)
    }
}
