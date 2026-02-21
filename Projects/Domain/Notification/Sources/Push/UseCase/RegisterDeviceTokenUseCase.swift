//
//  RegisterDeviceTokenUseCase.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/11/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


public protocol RegisterDeviceTokenUseCase: Sendable {
    func execute(devicePushToken: DevicePushToken) async throws(RepositoryError)
}

public final class DefaultRegisterDeviceTokenUseCase: RegisterDeviceTokenUseCase {
    private let repository: PushSettingRepository

    public init(repository: PushSettingRepository) {
        self.repository = repository
    }

    public func execute(devicePushToken: DevicePushToken) async throws(RepositoryError) {
        try await repository.registerDeviceToken(devicePushToken)
    }
}
