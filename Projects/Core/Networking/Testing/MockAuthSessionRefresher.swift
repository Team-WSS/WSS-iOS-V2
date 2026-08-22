import Foundation
@testable import Networking

/// 동시 요청 테스트에서 여러 스레드가 함께 호출하므로 카운터를 락으로 보호한다.
final class MockAuthSessionRefresher: AuthSessionRefreshing, @unchecked Sendable {
    enum Behavior {
        case success(Bool)
        case failure(Error)
    }

    private let lock = NSLock()
    private var callCount = 0
    private let onRefresh: () async throws -> Bool

    var refreshCallCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return callCount
    }

    init(behavior: Behavior) {
        switch behavior {
        case .success(let result):
            self.onRefresh = { result }
        case .failure(let error):
            self.onRefresh = { throw error }
        }
    }

    /// 지연·토큰 회전 등 갱신 도중의 동작을 직접 기술할 때 사용한다.
    init(onRefresh: @escaping () async throws -> Bool) {
        self.onRefresh = onRefresh
    }

    func refreshSession() async throws -> Bool {
        recordCall()
        return try await onRefresh()
    }

    /// `NSLock`은 async 컨텍스트에서 직접 쓸 수 없어 동기 메서드로 감싼다.
    private func recordCall() {
        lock.lock()
        defer { lock.unlock() }
        callCount += 1
    }
}
