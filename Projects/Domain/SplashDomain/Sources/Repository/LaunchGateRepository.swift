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
    /// 현재 앱 버전이 서버 최소 버전 미달인가. 미달이면 진입을 차단한다.
    func checkForceUpdateRequired() async throws(RepositoryError) -> Bool
    /// 필수 약관에 모두 동의했는가. 미동의면 홈 진입 시 약관 시트를 띄운다.
    func isRequiredTermsAgreed() async throws(RepositoryError) -> Bool
}
