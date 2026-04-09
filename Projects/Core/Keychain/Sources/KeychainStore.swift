import Foundation

public protocol KeychainStore {
    /// 새 항목을 생성합니다. 같은 key가 이미 있으면 실패합니다.
    func create(data: Data?, forKey key: String) throws

    /// key에 해당하는 항목을 조회합니다. 없으면 nil을 반환합니다.
    func read(forKey key: String) throws -> Data?

    /// 기존 항목을 수정합니다. 같은 key가 없으면 실패합니다.
    func update(data: Data?, forKey key: String) throws

    /// 항목이 있으면 수정하고, 없으면 생성합니다.
    func save(data: Data?, forKey key: String) throws

    /// key에 해당하는 항목을 삭제합니다.
    func delete(forKey key: String) throws
}
