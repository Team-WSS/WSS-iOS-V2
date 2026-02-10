//
//  MockAppUpdateRepository.swift
//  SettingDomain
//
//  Created by YunhakLee on 2/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
@testable import SettingDomain

final class MockAppUpdateRepository: AppUpdateRepository {
    var loadCallCount = 0
    var result: Result<AppUpdatePolicy, RepositoryError> = .success(
        AppUpdatePolicy(minimumVersion: .zero, updateDate: nil)
    )

    func loadAppUpdatePolicy() async throws(RepositoryError) -> AppUpdatePolicy {
        loadCallCount += 1
        return try result.get()
    }
}
