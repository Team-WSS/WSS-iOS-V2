//
//  PushAuthorizationChecker.swift
//  PushAuthorization
//
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

/// 시스템 푸시 알림 권한을 확인·요청하는 프로토콜. 다른 레이어는 이 프로토콜에만 의존한다
/// (Logger 모듈과 동일한 얇은 래퍼 패턴).
public protocol PushAuthorizationChecker: Sendable {
    /// 현재 권한 상태를 조회한다. 서버 호출이 아니라 로컬 시스템 조회라 실패하지 않는다.
    func authorizationStatus() async -> PushAuthorizationStatus

    /// 시스템 권한 요청 프롬프트를 띄운다. `notDetermined` 상태에서만 의미가 있다 —
    /// 이미 `denied`인 상태에서 호출하면 프롬프트 없이 즉시 `false`가 돌아온다(iOS 정책).
    /// 반환값은 사용자가 허용했는지 여부.
    func requestAuthorization() async -> Bool
}
