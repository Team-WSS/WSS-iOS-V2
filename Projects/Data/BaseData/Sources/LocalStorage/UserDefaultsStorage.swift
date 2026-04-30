//
//  UserDefaultsStorage.swift
//  BaseData
//
//  Created by Lee Wonsun on 4/30/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public protocol AppStorage {
    func get<V>(_ key: StorageKey<V>) -> V?
    func set<V>(_ key: StorageKey<V>, _ value: V?)
}

public final class UserDefaultsStorage: AppStorage {
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
}
