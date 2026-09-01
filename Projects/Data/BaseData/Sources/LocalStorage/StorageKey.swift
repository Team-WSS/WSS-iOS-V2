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
    public static var birthYear: StorageKey<Int> { .init("birthYear") }

    // 내 서재 필터·정렬 영속화(#221). JSON 직렬화된 스냅샷을 `Data`로 저장한다 —
    // V1의 두 키(`libraryFilterOption`/`librarySortOption`)를 하나로 합친 재설계 포맷.
    // ⚠️ `Value`가 `Data`이니 저장/조회 값도 항상 `Data`여야 한다(`UserDefaultsStorage`가 `as? V`라
    // 타입이 어긋나면 조용히 nil).
    public static var myLibraryFilter: StorageKey<Data> { .init("myLibraryFilter") }
}
