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
    /// 세션이 끝날 때(로그아웃·탈퇴 성공) UserDefaults에 남은 **사용자 개인 값**을 함께 지운다 —
    /// 남기면 계정을 갈아탄 다음 사용자 화면에 이전 사용자의 값(닉네임 등)이 비칠 수 있다(TODO 1절).
    /// 토큰 정리(clearTokens)와 같은 자리(성공 경로)에서만 부른다 — 서버 호출이 실패하면 세션이
    /// 안 끝난 것이므로 캐시도 보존한다.
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
