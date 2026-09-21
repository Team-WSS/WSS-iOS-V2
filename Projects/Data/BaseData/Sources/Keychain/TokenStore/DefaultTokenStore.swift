import Keychain

public struct DefaultTokenStore: TokenStore {
    private let keychainStore: KeychainStore

    public init(keychainStore: KeychainStore = KeychainClient()) {
        self.keychainStore = keychainStore
    }

    public func saveAccessToken(_ token: String) throws {
        try keychainStore.save(value: token, forKey: KeychainKey.Auth.accessToken.key)
    }

    public func saveRefreshToken(_ token: String) throws {
        try keychainStore.save(value: token, forKey: KeychainKey.Auth.refreshToken.key)
    }

    public func accessToken() throws -> String? {
        try keychainStore.value(forKey: KeychainKey.Auth.accessToken.key)
    }

    public func refreshToken() throws -> String? {
        try keychainStore.value(forKey: KeychainKey.Auth.refreshToken.key)
    }

    public func clearTokens() throws {
        try keychainStore.delete(forKey: KeychainKey.Auth.accessToken.key)
        try keychainStore.delete(forKey: KeychainKey.Auth.refreshToken.key)
    }
}
