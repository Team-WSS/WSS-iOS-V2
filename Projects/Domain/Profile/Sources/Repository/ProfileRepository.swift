//
//  ProfileRepository.swift
//  ProfileDomain
//
//  Created by YunhakLee on 2/24/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

public protocol ProfileRepository {
    func syncUserBasicInfo() async throws(RepositoryError)
}
