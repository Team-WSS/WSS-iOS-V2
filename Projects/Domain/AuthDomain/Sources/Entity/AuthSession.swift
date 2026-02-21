//
//  AuthSession.swift
//  AuthDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


public struct AuthSession: Equatable {
    public let accessToken: String
    public let refreshToken: String
    public let needOnboarding: Bool
}
