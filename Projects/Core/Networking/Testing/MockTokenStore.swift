@testable import Networking

final class MockTokenStore: SessionTokenStore {
    private let storedAccessToken: String?
    private(set) var clearTokensCallCount = 0

    init(accessToken: String?) {
        self.storedAccessToken = accessToken
    }

    func accessToken() throws -> String? { storedAccessToken }
    func clearTokens() throws { clearTokensCallCount += 1 }
}
