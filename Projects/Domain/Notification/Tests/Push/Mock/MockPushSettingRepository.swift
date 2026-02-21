//
//  MockPushSettingRepository.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Foundation
import NotificationDomain

final class MockPushSettingRepository: PushSettingRepository {

    // MARK: - Load

    var loadCallCount = 0
    var loadResult: Result<PushPreference, RepositoryError>?

    func loadPushPreference() async throws(RepositoryError) -> PushPreference {
        loadCallCount += 1
        guard let loadResult else {
            fatalError("loadResult가 설정되지 않았습니다.")
        }
        switch loadResult {
        case .success(let pref): return pref
        case .failure(let err): throw err
        }
    }

    // MARK: - Update

    var updateCallCount = 0
    var lastUpdatedPreference: PushPreference?
    var updateResult: Result<Void, RepositoryError>?

    func updatePushPreference(_ pref: PushPreference) async throws(RepositoryError) {
        updateCallCount += 1
        lastUpdatedPreference = pref

        if let updateResult {
            switch updateResult {
            case .success: return
            case .failure(let err): throw err
            }
        }
    }

    // MARK: - Register token

    var registerCallCount = 0
    var lastRegisteredToken: DevicePushToken?
    var registerResult: Result<Void, RepositoryError>?

    func registerDeviceToken(_ token: DevicePushToken) async throws(RepositoryError) {
        registerCallCount += 1
        lastRegisteredToken = token

        if let registerResult {
            switch registerResult {
            case .success: return
            case .failure(let err): throw err
            }
        }
    }
}
