//
//  UserDefaultsStorage.swift
//  BaseData
//
//  Created by Lee Wonsun on 4/30/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol AppStorage: Sendable {
    func get<V>(_ key: StorageKey<V>) -> V?
    func set<V>(_ key: StorageKey<V>, _ value: V?)
    func remove<V>(_ key: StorageKey<V>)
}

public extension AppStorage {
    /// 기본 구현은 `set(key, nil)` — 기존 conformer(테스트 목 포함)가 깨지지 않게 하기 위한 것.
    /// 실제 저장소는 명시적 삭제로 구현하는 편이 명확하다(`UserDefaultsStorage` 참고).
    func remove<V>(_ key: StorageKey<V>) {
        set(key, nil)
    }
}

public final class UserDefaultsStorage: AppStorage, @unchecked Sendable {
    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func get<V>(_ key: StorageKey<V>) -> V? {
        userDefaults.object(forKey: key.rawValue) as? V
    }

    public func set<V>(_ key: StorageKey<V>, _ value: V?) {
        userDefaults.set(value, forKey: key.rawValue)
    }

    public func remove<V>(_ key: StorageKey<V>) {
        userDefaults.removeObject(forKey: key.rawValue)
    }
}
