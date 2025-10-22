import Foundation

/// Keychain 저장소가 반드시 충족해야 하는 최소 계약
/// - 오직 Data 단위로만 CRUD를 정의합니다.
public protocol KeychainStoring {
    func create(data: Data?, forKey key: String) throws
    func read(forKey key: String) throws -> Data?
    func update(data: Data?, forKey key: String) throws
    func delete(forKey key: String) throws
}
