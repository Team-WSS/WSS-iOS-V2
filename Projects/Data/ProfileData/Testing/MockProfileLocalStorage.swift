//
//  MockProfileLocalStorage.swift
//  ProfileDataTesting
//
//  Created by WonsunLee on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseData

public final class MockProfileLocalStorage: AppStorage {
    private var storage: [String: Any] = [:]

    public init() {}

    public func get<V>(_ key: StorageKey<V>) -> V? {
        storage[key.rawValue] as? V
    }

    public func set<V>(_ key: StorageKey<V>, _ value: V?) {
        storage[key.rawValue] = value
    }

    public var userID: Int? {
        get { get(.userID) }
        set { set(.userID, newValue) }
    }

    public var nickname: String? {
        get { get(.nickname) }
        set { set(.nickname, newValue) }
    }

    public var characterID: Int? {
        get { get(.characterID) }
        set { set(.characterID, newValue) }
    }

    public var gender: String? {
        get { get(.gender) }
        set { set(.gender, newValue) }
    }
}
