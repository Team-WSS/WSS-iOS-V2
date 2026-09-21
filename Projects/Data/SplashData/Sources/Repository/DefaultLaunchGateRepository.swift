//
//  DefaultLaunchGateRepository.swift
//  SplashData
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain
import BaseData
import SettingDomain
import SplashDomain
import Networking

/// `LaunchGateRepository` 구현 — 로직 없이 기존 저장소·정책에 위임만 한다.
struct DefaultLaunchGateRepository: LaunchGateRepository {

    private let tokenStore: SessionTokenStore
    private let appStorage: AppStorage
    private let appUpdateRepository: AppUpdateRepository
    private let versionProvider: AppVersionProviding
    private let termsAgreementRepository: TermsAgreementRepository

    init(
        tokenStore: SessionTokenStore,
        appStorage: AppStorage,
        appUpdateRepository: AppUpdateRepository,
        versionProvider: AppVersionProviding,
        termsAgreementRepository: TermsAgreementRepository
    ) {
        self.tokenStore = tokenStore
        self.appStorage = appStorage
        self.appUpdateRepository = appUpdateRepository
        self.versionProvider = versionProvider
        self.termsAgreementRepository = termsAgreementRepository
    }

    /// 저장된 액세스 토큰의 존재 여부만 본다 — 만료 검증은 401 자동 재발급 경로(#184)가 담당.
    func hasValidSession() -> Bool {
        (try? tokenStore.accessToken()) != nil
    }

    /// 로컬 `isRegistered`(로그인 응답 isRegister 캐시, #257)를 읽는다 — `hasValidSession`이 토큰을
    /// 직접 읽는 것과 같은 결의 로컬 조회다. **값이 없으면 완료로 간주**(`?? true`) — 기능 도입 전
    /// 기존 로그인 유저를 온보딩으로 되돌리지 않기 위한 하위호환(포트 주석 참고).
    func isOnboardingCompleted() -> Bool {
        appStorage.get(.isRegistered) ?? true
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
