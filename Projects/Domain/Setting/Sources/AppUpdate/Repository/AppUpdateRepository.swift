//
//  AppUpdateRepository.swift
//  SettingDomain
//
//  Created by YunhakLee on 2/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public protocol AppUpdateRepository {
    func loadAppUpdatePolicy() async throws(RepositoryError) -> AppUpdatePolicy
}
