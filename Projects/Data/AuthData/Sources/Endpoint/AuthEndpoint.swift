//
//  AuthEndpoint.swift
//  AuthData
//
//  Created by YunhakLee on 4/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Foundation
import Networking
import BaseData

enum AuthEndpoint: Endpoint {
     
    case patchAppleAccountSync(AppleSyncRequest)
    case postAppleLogin(AppleLoginRequest)
    case postKakaoLogin(KakaoLoginRequestHeader)
    case postLogout(LogoutRequest)
    case postWithdraw(WithdrawRequest)
    case postReissueToken(ReissueRequest)
   
    
    var method: HTTPMethod {
        switch self {
        case .patchAppleAccountSync:    return .patch
        case .postAppleLogin:           return .post
        case .postKakaoLogin:           return .post
        case .postLogout:               return .post
        case .postWithdraw:             return .post
        case .postReissueToken:         return .post
        }
    }
    
    var baseURL: URL {
        // TODO: 컨피그 설정 후 baseURL 반영
        URL(string: NetworkingConfig.baseURL)!
    }
    
    var path: String {
        switch self {
        case .patchAppleAccountSync:    return "/auth/apple/sync"
        case .postAppleLogin:           return "/auth/login/apple"
        case .postKakaoLogin:           return "/auth/login/kakao"
        case .postLogout:               return "/auth/logout"
        case .postWithdraw:             return "/auth/withdraw"
        case .postReissueToken:         return "/reissue"
        }
    }

    var query: QueryParameters { .none }

    var additionalHeaders: [String: String]? { nil }
    
    var body: RequestBody {
        switch self {
        case .patchAppleAccountSync(let request): return .json(request)
        case .postAppleLogin(let request):        return .json(request)
        case .postKakaoLogin:                     return .none
        case .postLogout(let request):            return .json(request)
        case .postWithdraw(let request):          return .json(request)
        case .postReissueToken(let request):      return .json(request)
        }
    }
    
    var authorization: AuthorizationPolicy {
        switch self {
        case .patchAppleAccountSync, .postLogout, .postWithdraw:
            return .requireToken
        case .postAppleLogin, .postKakaoLogin, .postReissueToken:
            return .withoutToken
        }
    }
}
