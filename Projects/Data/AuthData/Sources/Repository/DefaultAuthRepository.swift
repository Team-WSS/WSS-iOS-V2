//
//  DefaultAuthRepository.swift
//  NotificationData
//
//  Created by YunhakLee on 3/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import AuthDomain
import BaseDomain
import BaseData
import Logger
import Networking

struct DefaultAuthRepository: AuthRepository {
    
    private let service: AuthService
    private let tokenStore: TokenStore
    private let deviceIdentifierStore: DeviceIdentifierStore
    private let appStorage: AppStorage
    private let logger: DataLogger?

    init(
        service: AuthService,
        tokenStore: TokenStore,
        deviceIdentifierStore: DeviceIdentifierStore,
        appStorage: AppStorage,
        logger: DataLogger?
    ) {
        self.service = service
        self.tokenStore = tokenStore
        self.deviceIdentifierStore = deviceIdentifierStore
        self.appStorage = appStorage
        self.logger = logger
    }
    
    public func login(
        with credential: SocialLoginCredential
    ) async throws(AuthError) -> NeedOnboarding {
        let action = AuthAction.login
        
        do {
            let loginResponse: LoginSuccessResponse
            switch credential {
            case .apple(let code, let idToken):
                let request = AppleLoginRequest(authorizationCode: code,
                                                idToken: idToken)
                loginResponse = try await service.postAppleLogin(request)
            case .kakao(let accessToken):
                let requestHeader = KakaoLoginRequestHeader(accessToken: accessToken)
                loginResponse = try await service.postKakaoLogin(requestHeader)
            }
            
            try tokenStore.saveAccessToken(loginResponse.accessToken)
            try tokenStore.saveRefreshToken(loginResponse.refreshToken)
            // 새 세션이 확정된 뒤(토큰 저장까지 성공), 남아 있을 수 있는 **이전 사용자**의 로컬 값을
            // 지운다 — 로그아웃/탈퇴 성공 경로는 스스로 지우지만, 401 만료·부트스트랩 `.intro` 낙착처럼
            // 서버가 세션을 끊은 경로는 지날 곳이 없어 여기가 모든 경로의 수렴점이다. 안 지우면 다른
            // 계정으로 로그인한 뒤 프로필 동기화가 실패했을 때 이전 사용자의 닉네임·서재 필터가 그대로
            // 비친다(#236 리뷰). 같은 계정 재로그인이어도 온보딩/홈 진입 전 동기화가 다시 채우므로 무해하다.
            // ⚠️ 토큰 저장보다 앞에 두지 말 것 — Keychain 저장이 throw하면 로그인은 실패인데 캐시만
            // 지워진 어정쩡한 상태가 된다(#236 리뷰).
            clearUserScopedCache()

            logger?.logSuccess(action: action.name)
            return AuthMapper.needOnboarding(from: loginResponse)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toAuthError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }
    
    public func logout() async throws(RepositoryError) {
        let action = AuthAction.logout
        
        do {
            guard let refreshToken = try tokenStore.refreshToken() else {
                throw RepositoryError.unknown
            }
            guard let deviceIdentifier = try deviceIdentifierStore.deviceIdentifier() else {
                throw RepositoryError.unknown
            }
            let request = LogoutRequest(refreshToken: refreshToken,
                                        deviceIdentifier: deviceIdentifier)
            try await service.postLogout(request)
            try tokenStore.clearTokens()
            clearUserScopedCache()
            logger?.logSuccess(action: action.name)
            
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }
    
    public func withdraw(
        draft: WithdrawalReasonDraft
    ) async throws(RepositoryError) {
        let action = AuthAction.withdraw
        
        do {
            let request = AuthMapper.withdrawalReason(from: draft)
            try await service.postWithdraw(request)
            try tokenStore.clearTokens()
            clearUserScopedCache()
            logger?.logSuccess(action: action.name)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }
    
    public func syncAppleCredential(
        _ credential: AppleSyncCredential
    ) async throws(RepositoryError) {
        let action = AuthAction.syncAppleCredential

        do {
            let request = AuthMapper.appleSyncRequest(from: credential)
            try await service.patchAppleAccountSync(request)
            logger?.logSuccess(action: action.name)
        } catch let error as NetworkingError {
            logger?.logNetworkError(action: action.name, error: error)
            throw error.toRepositoryError()
        } catch {
            logger?.logUnknownError(action: action.name, error: error)
            throw .unknown
        }
    }
}

private extension DefaultAuthRepository {
    /// 세션 경계에서 UserDefaults에 남은 **사용자 개인 값**을 지운다 — 남기면 계정을 갈아탄 다음
    /// 사용자 화면에 이전 사용자의 값(닉네임 등)이 비칠 수 있다(#236에서 해소).
    /// 부르는 곳은 세 성공 경로: 로그아웃·탈퇴(세션 종료 시점) + **로그인(새 세션 시작 직전)** —
    /// 로그인 쪽은 401 만료처럼 종료 시점을 지나지 않은 세션의 잔존 값까지 걷어내는 안전망이다.
    /// 서버 호출이 실패하면 세션 경계를 안 넘은 것이므로 캐시도 보존한다.
    /// ⚠️ `StorageKey`의 사용자 스코프 키가 늘면 여기도 같이 늘려야 한다(컴파일러가 못 잡아준다).
    func clearUserScopedCache() {
        appStorage.remove(.userID)
        appStorage.remove(.nickname)
        appStorage.remove(.characterID)
        appStorage.remove(.gender)
        appStorage.remove(.birthYear)
        // 내 서재 필터·정렬(#221)도 사용자별 선호라 함께 지운다 — 남기면 다음 계정의 서재에
        // 이전 사용자의 필터가 그대로 적용된다.
        appStorage.remove(.myLibraryFilter)
    }
}
