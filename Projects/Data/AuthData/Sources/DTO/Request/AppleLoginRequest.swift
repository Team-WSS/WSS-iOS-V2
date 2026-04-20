//
//  AppleLoginRequest.swift
//  AuthData
//
//  Created by YunhakLee on 4/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Networking

struct AppleLoginRequest: RequestBodyConvertible {
    let authorizationCode: String
    let idToken: String
}
