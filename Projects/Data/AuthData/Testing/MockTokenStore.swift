import BaseData

final class MockTokenStore: TokenStore {

    private(set) var savedAccessToken: String?
    private(set) var savedRefreshToken: String?
    private(set) var clearTokensCallCount = 0

    func saveAccessToken(_ token: String) throws { savedAccessToken = token }
    func saveRefreshToken(_ token: String) throws { savedRefreshToken = token }
    func accessToken() throws -> String? { savedAccessToken }
    func refreshToken() throws -> String? { savedRefreshToken }
    func clearTokens() throws {
        clearTokensCallCount += 1
        savedAccessToken = nil
        savedRefreshToken = nil
    }
}
