public protocol DeviceIdentifierStore {
    func deviceIdentifier() throws -> String?
    func saveDeviceIdentifier(_ identifier: String) throws
    func clearDeviceIdentifier() throws
}
