//
//  MockPushSettingRepository.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import NotificationDomain

public final class MockPushSettingRepository: PushSettingRepository {

    // MARK: - Load

    public var loadCallCount = 0
    public var loadResult: Result<PushPreference, RepositoryError>?

    public func loadPushPreference() async throws(RepositoryError) -> PushPreference {
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

    public var updateCallCount = 0
    public var lastUpdatedPreference: PushPreference?
    public var updateResult: Result<Void, RepositoryError>?

    public func updatePushPreference(_ pref: PushPreference) async throws(RepositoryError) {
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

    public var registerCallCount = 0
    public var lastRegisteredToken: DevicePushToken?
    public var registerResult: Result<Void, RepositoryError>?

    public func registerDeviceToken(_ token: DevicePushToken) async throws(RepositoryError) {
        registerCallCount += 1
        lastRegisteredToken = token

        if let registerResult {
            switch registerResult {
            case .success: return
            case .failure(let err): throw err
            }
        }
    }

    public init() {}
}
