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
import Keychain

public struct DefaultAuthRepository: AuthRepository {
    
    private let service: AuthService
    private let tokenStore: TokenStore
    private let deviceIdentifierStore: DeviceIdentifierStore
    private let logger: DataLogger?
    
    init(
        service: AuthService,
        tokenStore: TokenStore,
        deviceIdentifierStore: DeviceIdentifierStore,
        logger: DataLogger?
    ) {
        self.service = service
        self.tokenStore = tokenStore
        self.deviceIdentifierStore = deviceIdentifierStore
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
