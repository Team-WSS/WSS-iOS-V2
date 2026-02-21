//
//  UserDataStore.swift
//  AuthDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


public protocol UserDataStore {
    /// 로그아웃 시 사용자 관련 로컬 데이터(성별, UserID, 닉네임 등)제거
    func clearUserData()
}
