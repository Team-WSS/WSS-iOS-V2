//
//  RegisterDeviceTokenUseCaseTests.swift
//  NotificationDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


import Testing
import NotificationDomain

@Suite("RegisterDeviceTokenUseCase")
struct RegisterDeviceTokenUseCaseTests {

    private func makeToken() -> DevicePushToken {
        return DevicePushToken(token: "fcm_token", deviceID: "device_id")
    }

    @Test("디바이스 푸시 토큰을 등록할 수 있다")
    func registersDeviceTokenSuccessfully() async throws {
        let repo = MockPushSettingRepository()
        repo.registerResult = .success(())

        let sut = DefaultRegisterDeviceTokenUseCase(repository: repo)
        let token = makeToken()

        try await sut.execute(devicePushToken: token)

        #expect(repo.registerCallCount == 1)
        #expect(repo.lastRegisteredToken == token)
    }

    @Test("레포지토리에서 에러가 발생하면 그대로 전달한다")
    func propagatesRepositoryError() async {
        let repo = MockPushSettingRepository()
        repo.registerResult = .failure(.authenticationRequired)

        let sut = DefaultRegisterDeviceTokenUseCase(repository: repo)

        await #expect(throws: RepositoryError.authenticationRequired) {
            try await sut.execute(devicePushToken: makeToken())
        }

        #expect(repo.registerCallCount == 1)
    }
}
