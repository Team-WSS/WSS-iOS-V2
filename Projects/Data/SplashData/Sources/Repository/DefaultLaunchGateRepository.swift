//
//  DefaultLaunchGateRepository.swift
//  SplashData
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain
import Networking
import SettingDomain
import SplashDomain

/// `LaunchGateRepository` 구현 — 로직 없이 기존 저장소·정책에 위임만 한다.
struct DefaultLaunchGateRepository: LaunchGateRepository {

    private let tokenStore: SessionTokenStore
    private let appUpdateRepository: AppUpdateRepository
    private let versionProvider: AppVersionProviding
    private let termsAgreementRepository: TermsAgreementRepository

    init(
        tokenStore: SessionTokenStore,
        appUpdateRepository: AppUpdateRepository,
        versionProvider: AppVersionProviding,
        termsAgreementRepository: TermsAgreementRepository
    ) {
        self.tokenStore = tokenStore
        self.appUpdateRepository = appUpdateRepository
        self.versionProvider = versionProvider
        self.termsAgreementRepository = termsAgreementRepository
    }

    /// 저장된 액세스 토큰의 존재 여부만 본다 — 만료 검증은 401 자동 재발급 경로(#184)가 담당.
    func hasValidSession() -> Bool {
        ((try? tokenStore.accessToken()) ?? nil) != nil
    }

    /// 조회 실패 시 통과시킬지는 여기서 정하지 않는다(에러 그대로 전파) — 그 정책은 `BootstrapAppUseCase` 몫.
    func checkForceUpdateRequired() async throws(RepositoryError) -> Bool {
        let policy = try await appUpdateRepository.loadAppUpdatePolicy()
        return policy.requiresForceUpdate(current: versionProvider.currentVersion)
    }

    func isRequiredTermsAgreed() async throws(RepositoryError) -> Bool {
        let draft = try await termsAgreementRepository.loadTermsAgreementDraft()
        return draft.isSubmittable
    }
}
