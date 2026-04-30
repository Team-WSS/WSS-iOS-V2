import Keychain

extension KeychainKey {
    enum Auth: String, KeychainKeyRepresentable {
        case accessToken
        case refreshToken
    }

    enum Notification: String, KeychainKeyRepresentable {
        case deviceIdentifier
    }
}
