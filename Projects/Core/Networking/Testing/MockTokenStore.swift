import Foundation
@testable import Networking

/// 동시 요청 테스트에서 여러 스레드가 함께 접근하므로 락으로 보호한다.
final class MockTokenStore: SessionTokenStore, @unchecked Sendable {
    private let lock = NSLock()
    private var storedAccessToken: String?
    private var clearCount = 0

    var clearTokensCallCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return clearCount
    }

    init(accessToken: String?) {
        self.storedAccessToken = accessToken
    }

    func accessToken() throws -> String? {
        lock.lock()
        defer { lock.unlock() }
        return storedAccessToken
    }

    func clearTokens() throws {
        lock.lock()
        defer { lock.unlock() }
        clearCount += 1
        storedAccessToken = nil
    }

    /// 서버의 토큰 회전을 흉내낸다.
    func update(accessToken: String?) {
        lock.lock()
        defer { lock.unlock() }
        storedAccessToken = accessToken
    }
}
