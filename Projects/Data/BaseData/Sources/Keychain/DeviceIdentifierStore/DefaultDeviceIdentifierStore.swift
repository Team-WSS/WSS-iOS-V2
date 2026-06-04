import Keychain

public struct DefaultDeviceIdentifierStore: DeviceIdentifierStore {
    private let keychainStore: KeychainStore

    public init(keychainStore: KeychainStore = KeychainClient()) {
        self.keychainStore = keychainStore
    }

    public func deviceIdentifier() throws -> String? {
        try keychainStore.value(forKey: KeychainKey.Notification.deviceIdentifier.key)
    }

    public func saveDeviceIdentifier(_ identifier: String) throws {
        try keychainStore.save(value: identifier, forKey: KeychainKey.Notification.deviceIdentifier.key)
    }

    public func clearDeviceIdentifier() throws {
        try keychainStore.delete(forKey: KeychainKey.Notification.deviceIdentifier.key)
    }
}
