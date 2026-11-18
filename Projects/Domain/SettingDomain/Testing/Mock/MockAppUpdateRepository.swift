//
//  MockAppUpdateRepository.swift
//  SettingDomain
//
//  Created by YunhakLee on 2/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import SettingDomain
import BaseDomain

public final class MockAppUpdateRepository: AppUpdateRepository {
    public var result: Result<AppUpdatePolicy, RepositoryError> = .success(
        AppUpdatePolicy(minimumVersion: .zero, updateDate: nil)
    )

    public init() {}

    public func loadAppUpdatePolicy() async throws(RepositoryError) -> AppUpdatePolicy {
        try result.get()
    }
}
