//
//  LoginSuccessResponse.swift
//  AuthData
//
//  Created by YunhakLee on 4/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

struct LoginSuccessResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let isRegister: Bool
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "Authorization"
        case refreshToken = "refreshToken"
        case isRegister = "isRegister"
    }
}
