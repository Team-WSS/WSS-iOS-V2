//
//  SocialLoginCredential.swift
//  AuthDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


public enum SocialLoginCredential: Equatable {
    case apple(
        authorizationCode: String,
        idToken: String
    )
    case kakao(
        accessToken: String
    )
}
