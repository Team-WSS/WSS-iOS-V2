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

    // 로그인 응답 `isRegister`(true=가입 완료 = 온보딩 불필요)를 로컬에 영속화(#257). 세션(토큰)은 있으나
    // 이 값이 `false`(로그인만 하고 온보딩 미완료)면 런치 부트스트랩이 인트로로 되돌린다. 로그인 시
    // 서버 값으로 갱신, 온보딩(프로필 등록) 완료 시 `true`로 갱신, 로그아웃/탈퇴 시 삭제한다.
    // ⚠️ **키가 없으면(기능 도입 전 기존 로그인 유저) "가입 완료"로 간주**한다(부트스트랩이 `?? true`로 읽음) —
    // 기존 유저를 온보딩으로 되돌리지 않기 위한 하위호환. 사용자 스코프 값이라 `clearUserScopedCache`가 지운다.
    public static var isRegistered: StorageKey<Bool> { .init("isRegistered") }
}
