import Keychain

final class MockTokenStore: TokenStore {

    private(set) var savedAccessToken: String?
    private(set) var savedRefreshToken: String?

    func saveAccessToken(_ token: String) throws { savedAccessToken = token }
    func saveRefreshToken(_ token: String) throws { savedRefreshToken = token }
    func accessToken() throws -> String? { savedAccessToken }
    func refreshToken() throws -> String? { savedRefreshToken }
    func clearTokens() throws { savedAccessToken = nil; savedRefreshToken = nil }
}
