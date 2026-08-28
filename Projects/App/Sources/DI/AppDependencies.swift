//
//  AppDependencies.swift
//  WSS-iOS
//
//  Created by Guryss on 8/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain
import AuthDomain
import ProfileDomain
import SettingDomain
import BaseData
import AuthData
import ProfileData
import SettingData
import Logger
import Networking

/// App(DI)의 유일한 조립 지점 — Data 구현체와 Domain 프로토콜이 만나는 곳.
/// 온보딩 플로우가 필요로 하는 Repository까지 조립한다.
///
/// **NetworkingClient가 2개인 이유(무한 재귀 방지)**: `refresherClient`는 토큰 갱신 자체를 요청하는
/// 전용 client라 `authSessionRefresher`를 물리지 않는다 — 물리면 "갱신 요청 401 → 갱신 시도 → 그 요청도
/// 401 → ..."로 재귀한다(`AuthData/CLAUDE.md` 경고). 실제 API 호출은 전부 `client`(갱신 훅 연결됨)로 나간다.
/// 두 client는 같은 `tokenStore`(Keychain 기반)를 공유해 갱신된 토큰이 즉시 반영된다.
@MainActor
final class AppDependencies {

    let logger: Logger
    let authRepository: AuthRepository
    let termsAgreementRepository: TermsAgreementRepository
    let profileRepository: ProfileRepository

    init() {
        let logger = ConsoleLogger()
        self.logger = logger

        let tokenStore = DefaultTokenStore()

        let refresherClient = NetworkingClient(
            logger: DefaultNetworkLogger(base: logger),
            tokenStore: tokenStore
        )
        let sessionRefresher = AuthDataFactory.makeSessionRefresher(
            client: refresherClient,
            tokenStore: tokenStore,
            logger: DataLogger(moduleName: "AuthData", underlying: logger)
        )

        let client = NetworkingClient(
            logger: DefaultNetworkLogger(base: logger),
            tokenStore: tokenStore,
            authSessionRefresher: sessionRefresher
        )

        self.authRepository = AuthDataFactory.makeRepository(
            client: client,
            tokenStore: tokenStore,
            deviceIdentifierStore: DefaultDeviceIdentifierStore(),
            logger: DataLogger(moduleName: "AuthData", underlying: logger)
        )
        self.termsAgreementRepository = SettingDataFactory.makeTermsAgreementRepository(
            client: client,
            logger: DataLogger(moduleName: "SettingData", underlying: logger)
        )
        self.profileRepository = ProfileDataFactory.makeProfileRepository(
            client: client,
            localStorage: UserDefaultsStorage(),
            logger: DataLogger(moduleName: "ProfileData", underlying: logger)
        )
    }
}
