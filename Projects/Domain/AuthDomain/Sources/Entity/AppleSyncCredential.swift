//
//  AppleSyncCredential.swift
//  AuthDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


public struct AppleSyncCredential: Equatable {
    public let authorizationCode: String
    public let idToken: String
}
