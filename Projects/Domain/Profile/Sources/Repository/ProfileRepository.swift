//
//  ProfileRepository.swift
//  ProfileDomain
//
//  Created by YunhakLee on 2/24/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

public protocol ProfileRepository {
    
    /// 받아온 성별, userID, 닉네임을 userDefaults에 저장
    func syncUserBasicInfo() async throws(RepositoryError)
    func validateNickname(_ nickname: String) async throws(RepositoryError) -> Bool
    func registerProfile(_ profile: ProfileRegistration) async throws(RepositoryError)
}
