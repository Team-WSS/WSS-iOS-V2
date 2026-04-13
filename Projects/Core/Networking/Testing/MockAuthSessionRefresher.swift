@testable import Networking

final class MockAuthSessionRefresher: AuthSessionRefreshing {
    enum Behavior {
        case success(Bool)
        case failure(Error)
    }

    private let behavior: Behavior
    private(set) var refreshCallCount = 0

    init(behavior: Behavior) {
        self.behavior = behavior
    }

    func refreshSession() async throws -> Bool {
        refreshCallCount += 1

        switch behavior {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        }
    }
}
