//
//  MyLibraryFilterRepository.swift
//  NovelDomain
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

/// 내 서재 필터·정렬 상태의 **로컬 영속화** 계약(#221).
///
/// 서버·userID와 무관한 순수 로컬 저장이라 서버 조회 계약(`NovelRepository`)과 **일부러 분리**했다 —
/// 이렇게 두면 `NovelRepository`를 목킹하는 여러 화면·Demo·테스트를 건드리지 않는다.
///
/// 저장/복원 모두 **best-effort**다: 실패해도 던지지 않고(복원 실패 = nil → 화면은 기본 필터로 시작),
/// 화면 진입을 막지 않는다. 그래서 `async throws`가 아니라 **동기·비-throwing**이다 — ViewModel이
/// `init`에서 **동기로 복원**해 첫 로드가 복원된 필터로 나가야 첫 프레임에 기본 필터가 스치지 않는다.
public protocol MyLibraryFilterRepository: Sendable {

    /// 마지막으로 저장된 필터·정렬을 복원한다. 저장된 게 없거나 복원에 실패하면 nil.
    func loadFilter() -> MyLibraryFilter?

    /// 현재 필터·정렬을 저장한다(다음 앱 실행에서 복원된다).
    func saveFilter(_ filter: MyLibraryFilter)
}
