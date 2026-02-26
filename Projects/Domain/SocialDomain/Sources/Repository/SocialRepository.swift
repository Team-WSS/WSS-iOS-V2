//
//  SocialRepository.swift
//  SocialDomain
//
//  Created by YunhakLee on 2/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public protocol SocialRepository {
    func blockUser(id: UserID) async throws(RepositoryError)
    func loadBlockedUsers() async throws(RepositoryError)
}
