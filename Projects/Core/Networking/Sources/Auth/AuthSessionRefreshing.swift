//
//  AuthSessionRefreshing.swift
//  Networking
//
//  Created by YunhakLee on 4/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


public protocol AuthSessionRefreshing {
    
    /// 해당 요청의 Endpoint에서 authorization 값은 반드시 .withoutToken이어야 함.
    /// 새로 받아온 Access Token, Refresh Token 모두 TokenStore에 저장해야 함!
    func refreshSession() async throws -> Bool
}
