//
//  TokenStore.swift
//  AuthDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


public protocol TokenStore {
    func save(_ session: AuthSession)
    /// 로그아웃 시 acess, refresh Token 모두 삭제
    func clear()
}
