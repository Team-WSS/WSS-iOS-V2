//
//  StorageKey.swift
//  BaseData
//
//  Created by Lee Wonsun on 4/30/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct StorageKey<Value> {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

// MARK: 용도별 Key 관리

// 공용 키

extension StorageKey {
    public static var userID: StorageKey<Int> { .init("userID") }
    public static var nickname: StorageKey<String> { .init("nickname") }
    public static var characterID: StorageKey<Int> { .init("characterID") }
    public static var gender: StorageKey<String> { .init("gender") }
}
