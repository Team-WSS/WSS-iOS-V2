//
//  LaunchTaskRepository.swift
//  SplashDomain
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

/// 진입 시 수행하는 부수 태스크들 — 실패해도 앱 진입을 막지 않는다.
///
/// 전부 세션이 있을 때만 의미가 있다. 구현은 SplashData가 기존 저장소들에 위임한다.
public protocol LaunchTaskRepository: Sendable {
    /// 유저 정보(`/users/me`)를 조회해 로컬 캐시(userId·nickname·gender·birth)를 갱신한다.
    func syncUserBasicInfo() async throws(RepositoryError)
    /// FCM 디바이스 토큰을 서버에 등록한다(푸시 권한이 있을 때만).
    func registerDeviceTokenIfNeeded() async throws(RepositoryError)
    /// 키워드 로컬 캐시를 서버와 동기화한다.
    func syncKeywords() async
    /// 홈 첫 화면 데이터(오늘의 발견·지금 뜨는 글)를 미리 받아 single-shot store를 채운다.
    func prefetchHomeData() async
}
