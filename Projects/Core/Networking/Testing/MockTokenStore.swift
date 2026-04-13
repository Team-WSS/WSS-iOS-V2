import Keychain

final class MockTokenStore: TokenStore {
    private let storedAccessToken: String?

    init(accessToken: String?) {
        self.storedAccessToken = accessToken
    }

    func saveAccessToken(_ token: String) throws { }
    func saveRefreshToken(_ token: String) throws { }
    func accessToken() throws -> String? { storedAccessToken }
    func refreshToken() throws -> String? { nil }
    func clearTokens() throws { }
}
