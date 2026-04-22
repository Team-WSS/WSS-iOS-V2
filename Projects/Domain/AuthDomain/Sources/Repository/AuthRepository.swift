//
//  AuthRepository.swift
//  AuthDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain

public protocol AuthRepository {
    func login(
        with credential: SocialLoginCredential
    ) async throws(AuthError) -> NeedOnboarding
    
    /// 토큰과 개인 정보 삭제도 필요
    func logout() async throws(RepositoryError)
    
    /// 토큰과 개인 정보 삭제도 필요
    func withdraw(
        draft: WithdrawalReasonDraft
    ) async throws(RepositoryError)
    
    /// 앱 소유자 변경 문제로, 기존에 Apple로 로그인한 사용자의 새로운 Apple 인증 정보를
    /// 사용하여 서버에 저장된 사용자 정보를 갱신합니다.
    func syncAppleCredential(
        _ credential: AppleSyncCredential
    ) async throws(RepositoryError)
}
