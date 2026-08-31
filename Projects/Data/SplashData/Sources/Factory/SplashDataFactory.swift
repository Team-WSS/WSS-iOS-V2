//
//  SplashDataFactory.swift
//  SplashData
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain
import Networking
import NotificationDomain
import ProfileDomain
import RecommendationDomain
import SettingDomain
import SplashDomain

/// SplashData 진입점 — 다른 Data 팩토리와 달리 네트워크 클라이언트가 아니라
/// **이미 조립된 도메인 Repository들**을 받는다(composite 모듈이라 자기 네트워크 호출이 없다).
public enum SplashDataFactory {

    public static func makeLaunchGateRepository(
        tokenStore: SessionTokenStore,
        appUpdateRepository: AppUpdateRepository,
        versionProvider: AppVersionProviding,
        termsAgreementRepository: TermsAgreementRepository
    ) -> LaunchGateRepository {
        DefaultLaunchGateRepository(
            tokenStore: tokenStore,
            appUpdateRepository: appUpdateRepository,
            versionProvider: versionProvider,
            termsAgreementRepository: termsAgreementRepository
        )
    }

    public static func makeLaunchTaskRepository(
        profileRepository: ProfileRepository,
        pushSettingRepository: PushSettingRepository,
        deviceTokenProvider: @escaping @Sendable () async -> DevicePushToken?,
        keywordRepository: KeywordRepository,
        recommendationRepository: RecommendationRepository,
        prefetchStore: HomePrefetchStore
    ) -> LaunchTaskRepository {
        DefaultLaunchTaskRepository(
            profileRepository: profileRepository,
            pushSettingRepository: pushSettingRepository,
            deviceTokenProvider: deviceTokenProvider,
            keywordRepository: keywordRepository,
            recommendationRepository: recommendationRepository,
            prefetchStore: prefetchStore
        )
    }
}
