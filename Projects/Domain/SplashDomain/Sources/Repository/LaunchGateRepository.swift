//
//  LaunchGateRepository.swift
//  SplashDomain
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

/// 라우팅·차단 판정에 쓰는 질문들.
///
/// 답의 출처(Keychain·서버)는 모른다 — 구현은 SplashData가 기존 저장소들에 위임한다.
public protocol LaunchGateRepository: Sendable {
    /// 저장된 세션(토큰)이 있는가. 없으면 인트로로 라우팅된다.
    func hasValidSession() -> Bool
    /// 온보딩(회원가입)을 끝냈는가(로그인 응답 isRegister의 로컬 캐시, #257). 세션은 있으나 이 값이
    /// false면(로그인만 하고 온보딩 미완료) 인트로로 되돌린다. 값을 정한 적 없으면(기능 도입 전 기존
    /// 로그인 유저) **완료로 간주**한다 — 기존 유저를 온보딩으로 되돌리지 않기 위함(구현이 `?? true`).
    func isOnboardingCompleted() -> Bool
    /// 현재 앱 버전이 서버 최소 버전 미달인가. 미달이면 진입을 차단한다.
    func checkForceUpdateRequired() async throws(RepositoryError) -> Bool
    /// 필수 약관에 모두 동의했는가. 미동의면 홈 진입 시 약관 시트를 띄운다.
    func isRequiredTermsAgreed() async throws(RepositoryError) -> Bool
}
