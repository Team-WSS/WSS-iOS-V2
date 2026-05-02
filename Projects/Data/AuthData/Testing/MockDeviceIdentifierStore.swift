import Keychain

final class MockDeviceIdentifierStore: DeviceIdentifierStore {

    private var storedDeviceIdentifier: String?

    init(deviceIdentifier: String? = nil) {
        self.storedDeviceIdentifier = deviceIdentifier
    }

    func deviceIdentifier() throws -> String? { storedDeviceIdentifier }
    func saveDeviceIdentifier(_ identifier: String) throws {
        storedDeviceIdentifier = identifier
    }
    func clearDeviceIdentifier() throws {
        storedDeviceIdentifier = nil
    }
}
