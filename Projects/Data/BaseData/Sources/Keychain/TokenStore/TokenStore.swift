import Networking

public protocol TokenStore: SessionTokenStore {
    func saveAccessToken(_ token: String) throws
    func saveRefreshToken(_ token: String) throws
    func refreshToken() throws -> String?
    
    // MARK: - SessionTokenStore
    
    func accessToken() throws -> String?
    func clearTokens() throws
}
