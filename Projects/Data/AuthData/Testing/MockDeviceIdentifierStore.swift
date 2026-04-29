import Keychain

final class MockDeviceIdentifierStore: DeviceIdentifierStore {

    func deviceIdentifier() throws -> String? { nil }
    func saveDeviceIdentifier(_ identifier: String) throws { }
    func clearDeviceIdentifier() throws { }
}
