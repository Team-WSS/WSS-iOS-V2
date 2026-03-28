//
//  DefaultPushSettingRepositoryTests.swift
//  NotificationData
//
//  Created by YunhakLee on 3/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import NotificationData
@testable import NotificationDataTesting
import NotificationDomain
import BaseDomain
import Networking


@Suite("DefaultPushSettingRepository")
struct DefaultPushSettingRepositoryTests {

    // MARK: - Helpers

    private func makeRepository(
        service: MockPushSettingService,
        logger: MockPushSettingLogger? = nil
    ) -> DefaultPushSettingRepository {
        DefaultPushSettingRepository(
            pushSettingService: service,
            logger: logger
        )
    }

    private func makePushPreference() -> PushPreference {
        PushPreference(isEnabled: true)
    }

    private func makePushNotificationSettingResponse() -> PushNotificationSettingResponse {
        PushNotificationSettingResponse(isPushEnabled: true)
    }

    private func makeDevicePushToken() -> DevicePushToken {
        DevicePushToken(token: "sample-device-token", deviceID: "sample-device-ID")
    }

    // MARK: - loadPushPreference

    @Test("푸시 설정 조회에 성공하면 PushPreference를 반환한다")
    func loadsPushPreferenceSuccessfully() async throws {
        let service = MockPushSettingService()
        let logger = MockPushSettingLogger()
        service.getPushNotificationSettingResult = .success(
            makePushNotificationSettingResponse()
        )

        let sut = makeRepository(service: service, logger: logger)

        let result = try await sut.loadPushPreference()

        #expect(result == makePushPreference())
        #expect(logger.loggedErrors.isEmpty)
    }

    @Test("푸시 설정 조회 중 networking 에러가 발생하면 RepositoryError로 변환하고 network 로그를 남긴다")
    func translatesNetworkingErrorOnLoadPushPreference() async {
        let service = MockPushSettingService()
        let logger = MockPushSettingLogger()
        service.getPushNotificationSettingResult = .failure(
            NetworkingError.responseFailure(code: 401, body: nil)
        )

        let sut = makeRepository(service: service, logger: logger)

        await #expect(throws: RepositoryError.authenticationRequired) {
            _ = try await sut.loadPushPreference()
        }

        #expect(logger.loggedErrors == [
            .init(type: .network, action: .loadPreference)
        ])
    }

    @Test("푸시 설정 조회 중 알 수 없는 에러가 발생하면 unknown 에러를 던지고 unknown 로그를 남긴다")
    func throwsUnknownWhenUnknownErrorOccursOnLoadPushPreference() async {
        let service = MockPushSettingService()
        let logger = MockPushSettingLogger()
        service.getPushNotificationSettingResult = .failure(MockError.sample)

        let sut = makeRepository(service: service, logger: logger)

        await #expect(throws: RepositoryError.unknown) {
            _ = try await sut.loadPushPreference()
        }

        #expect(logger.loggedErrors == [
            .init(type: .unknown, action: .loadPreference)
        ])
    }

    // MARK: - updatePushPreference

    @Test("푸시 설정 수정에 성공하면 설정 요청을 service에 전달한다")
    func updatesPushPreferenceSuccessfully() async throws {
        let service = MockPushSettingService()
        let logger = MockPushSettingLogger()
        let preference = makePushPreference()

        service.postPushNotificationSettingResult = .success(())

        let sut = makeRepository(service: service, logger: logger)

        try await sut.updatePushPreference(preference)

        #expect(logger.loggedErrors.isEmpty)
    }

    @Test("푸시 설정 수정 중 networking 에러가 발생하면 RepositoryError로 변환하고 network 로그를 남긴다")
    func translatesNetworkingErrorOnUpdatePushPreference() async {
        let service = MockPushSettingService()
        let logger = MockPushSettingLogger()
        let preference = makePushPreference()

        service.postPushNotificationSettingResult = .failure(
            NetworkingError.responseFailure(code: 404, body: nil)
        )

        let sut = makeRepository(service: service, logger: logger)

        await #expect(throws: RepositoryError.notFound) {
            try await sut.updatePushPreference(preference)
        }

        #expect(logger.loggedErrors == [
            .init(type: .network, action: .updatePreference)
        ])
    }

    @Test("푸시 설정 수정 중 알 수 없는 에러가 발생하면 unknown 에러를 던지고 unknown 로그를 남긴다")
    func throwsUnknownWhenUnknownErrorOccursOnUpdatePushPreference() async {
        let service = MockPushSettingService()
        let logger = MockPushSettingLogger()
        let preference = makePushPreference()

        service.postPushNotificationSettingResult = .failure(MockError.sample)

        let sut = makeRepository(service: service, logger: logger)

        await #expect(throws: RepositoryError.unknown) {
            try await sut.updatePushPreference(preference)
        }

        #expect(logger.loggedErrors == [
            .init(type: .unknown, action: .updatePreference)
        ])
    }

    // MARK: - registerDeviceToken

    @Test("디바이스 토큰 등록에 성공하면 토큰 요청을 service에 전달한다")
    func registersDeviceTokenSuccessfully() async throws {
        let service = MockPushSettingService()
        let logger = MockPushSettingLogger()
        let token = makeDevicePushToken()

        service.postFCMTokenResult = .success(())

        let sut = makeRepository(service: service, logger: logger)

        try await sut.registerDeviceToken(token)

        #expect(logger.loggedErrors.isEmpty)
    }

    @Test("디바이스 토큰 등록 중 networking 에러가 발생하면 RepositoryError로 변환하고 network 로그를 남긴다")
    func translatesNetworkingErrorOnRegisterDeviceToken() async {
        let service = MockPushSettingService()
        let logger = MockPushSettingLogger()
        let token = makeDevicePushToken()

        service.postFCMTokenResult = .failure(
            NetworkingError.responseFailure(code: 500, body: nil)
        )

        let sut = makeRepository(service: service, logger: logger)

        await #expect(throws: RepositoryError.serverUnavailable) {
            try await sut.registerDeviceToken(token)
        }

        #expect(logger.loggedErrors == [
            .init(type: .network, action: .registerToken)
        ])
    }

    @Test("디바이스 토큰 등록 중 알 수 없는 에러가 발생하면 unknown 에러를 던지고 unknown 로그를 남긴다")
    func throwsUnknownWhenUnknownErrorOccursOnRegisterDeviceToken() async {
        let service = MockPushSettingService()
        let logger = MockPushSettingLogger()
        let token = makeDevicePushToken()

        service.postFCMTokenResult = .failure(MockError.sample)

        let sut = makeRepository(service: service, logger: logger)

        await #expect(throws: RepositoryError.unknown) {
            try await sut.registerDeviceToken(token)
        }

        #expect(logger.loggedErrors == [
            .init(type: .unknown, action: .registerToken)
        ])
    }
}
