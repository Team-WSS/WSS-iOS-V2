//
//  AuthError.swift
//  AuthDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

public enum AuthError: Error {
    case networkUnavailable
    case invalidCredential
    case providerUnavailable
    case unknown
}
