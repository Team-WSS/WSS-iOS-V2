import Testing
@testable import AuthData
@testable import AuthDataTesting
import AuthDomain
import BaseData
import BaseDomain
import Logger
import Networking

@Suite("DefaultAuthRepository")
struct DefaultAuthRepositoryTests {

    // MARK: - Helpers

    private func makeRepository(
        service: MockAuthService = MockAuthService(),
        tokenStore: MockTokenStore = MockTokenStore(),
        deviceIdentifierStore: MockDeviceIdentifierStore = MockDeviceIdentifierStore(),
        logger: DataLogger? = nil
    ) -> DefaultAuthRepository {
        DefaultAuthRepository(
            service: service,
            tokenStore: tokenStore,
            deviceIdentifierStore: deviceIdentifierStore,
            logger: logger
        )
    }

    private func makeDataLogger(underlying: Logger) -> DataLogger {
        DataLogger(moduleName: "AuthData", underlying: underlying)
    }

    private func makeLoginSuccessResponse(
        accessToken: String = "access",
        refreshToken: String = "refresh",
        isRegister: Bool = true
    ) -> LoginSuccessResponse {
        LoginSuccessResponse(
            accessToken: accessToken,
            refreshToken: refreshToken,
            isRegister: isRegister
        )
    }

    // MARK: - login

    @Test("Apple 로그인 성공 시 postAppleLogin 호출 및 토큰 저장")
    func loginWithAppleCredentialSucceeds() async throws {
        let service = MockAuthService()
        let tokenStore = MockTokenStore()
        service.postAppleLoginResult = .success(makeLoginSuccessResponse(
            accessToken: "appleAccess",
            refreshToken: "appleRefresh",
            isRegister: false
        ))

        let sut = makeRepository(service: service, tokenStore: tokenStore)
        let result = try await sut.login(with: .apple(authorizationCode: "code", idToken: "token"))

        #expect(service.requestedAppleLogin?.authorizationCode == "code")
        #expect(service.requestedAppleLogin?.idToken == "token")
        #expect(tokenStore.savedAccessToken == "appleAccess")
        #expect(tokenStore.savedRefreshToken == "appleRefresh")
        #expect(result == NeedOnboarding(value: true))
    }

    @Test("Kakao 로그인 성공 시 postKakaoLogin 호출 및 토큰 저장")
    func loginWithKakaoCredentialSucceeds() async throws {
        let service = MockAuthService()
        let tokenStore = MockTokenStore()
        service.postKakaoLoginResult = .success(makeLoginSuccessResponse(
            accessToken: "kakaoAccess",
            refreshToken: "kakaoRefresh",
            isRegister: true
        ))

        let sut = makeRepository(service: service, tokenStore: tokenStore)
        let result = try await sut.login(with: .kakao(accessToken: "kakaoToken"))

        #expect(service.requestedKakaoLoginHeader?.accessToken == "kakaoToken")
        #expect(tokenStore.savedAccessToken == "kakaoAccess")
        #expect(tokenStore.savedRefreshToken == "kakaoRefresh")
        #expect(result == NeedOnboarding(value: false))
    }

    @Test("NetworkingError를 AuthError로 올바르게 변환한다")
    func translatesNetworkingErrorToAuthError() async {
        let cases: [(error: NetworkingError, expected: AuthError)] = [
            (.responseFailure(code: 400, body: nil), .invalidCredential),
            (.responseFailure(code: 499, body: nil), .invalidCredential),
            (.responseFailure(code: 500, body: nil), .providerUnavailable),
            (.responseFailure(code: 599, body: nil), .providerUnavailable),
            (.unknown(MockError.sample), .networkUnavailable),
            (.decoding, .invalidData),
        ]

        for (networkingError, expectedAuthError) in cases {
            let service = MockAuthService()
            service.postAppleLoginResult = .failure(networkingError)
            let sut = makeRepository(service: service)

            await #expect(throws: expectedAuthError) {
                _ = try await sut.login(with: .apple(authorizationCode: "code", idToken: "token"))
            }
        }
    }

    @Test("알 수 없는 에러 발생 시 unknown AuthError 반환")
    func throwsUnknownOnUnexpectedError() async {
        let service = MockAuthService()
        service.postAppleLoginResult = .failure(MockError.sample)
        let sut = makeRepository(service: service)

        await #expect(throws: AuthError.unknown) {
            _ = try await sut.login(with: .apple(authorizationCode: "code", idToken: "token"))
        }
    }

    // MARK: - logout

    @Test("로그아웃 성공 시 요청 완료 후 성공 로그를 남긴다")
    func logoutSucceedsAndLogsSuccess() async throws {
        let service = MockAuthService()
        let tokenStore = MockTokenStore()
        try tokenStore.saveRefreshToken("refresh")
        let deviceIdentifierStore = MockDeviceIdentifierStore(deviceIdentifier: "device")
        let logger = MockLogger()

        let sut = makeRepository(
            service: service,
            tokenStore: tokenStore,
            deviceIdentifierStore: deviceIdentifierStore,
            logger: makeDataLogger(underlying: logger)
        )

        try await sut.logout()

        #expect(service.requestedLogout?.refreshToken == "refresh")
        #expect(service.requestedLogout?.deviceIdentifier == "device")
        #expect(logger.debugMessages.contains { $0.contains("logout succeeded") })
    }

    @Test("로그아웃 요청 실패 시 성공 로그를 남기지 않는다")
    func logoutFailureDoesNotLogSuccess() async {
        let service = MockAuthService()
        service.postLogoutResult = .failure(NetworkingError.responseFailure(code: 500, body: nil))
        let tokenStore = MockTokenStore()
        try? tokenStore.saveRefreshToken("refresh")
        let deviceIdentifierStore = MockDeviceIdentifierStore(deviceIdentifier: "device")
        let logger = MockLogger()

        let sut = makeRepository(
            service: service,
            tokenStore: tokenStore,
            deviceIdentifierStore: deviceIdentifierStore,
            logger: makeDataLogger(underlying: logger)
        )

        await #expect(throws: RepositoryError.serverUnavailable) {
            try await sut.logout()
        }
        #expect(logger.debugMessages.isEmpty)
    }

    // MARK: - withdraw

    @Test("회원 탈퇴 성공 시 성공 로그를 남긴다")
    func withdrawSucceedsAndLogsSuccess() async throws {
        let service = MockAuthService()
        let logger = MockLogger()
        let sut = makeRepository(
            service: service,
            logger: makeDataLogger(underlying: logger)
        )

        try await sut.withdraw(draft: WithdrawalReasonDraft())

        #expect(service.requestedWithdraw?.reason == "자주 사용하지 않아서")
        #expect(logger.debugMessages.contains { $0.contains("withdraw succeeded") })
    }

    // MARK: - syncAppleCredential

    @Test("Apple 계정 연동 성공 시 성공 로그를 남긴다")
    func syncAppleCredentialSucceedsAndLogsSuccess() async throws {
        let service = MockAuthService()
        let logger = MockLogger()
        let sut = makeRepository(
            service: service,
            logger: makeDataLogger(underlying: logger)
        )
        let credential = AppleSyncCredential(
            authorizationCode: "code",
            idToken: "idToken"
        )

        try await sut.syncAppleCredential(credential)

        #expect(service.requestedAppleSync?.authorizationCode == "code")
        #expect(service.requestedAppleSync?.idToken == "idToken")
        #expect(logger.debugMessages.contains { $0.contains("syncAppleCredential succeeded") })
    }
}

private final class MockLogger: Logger {
    private(set) var debugMessages: [String] = []
    private(set) var infoMessages: [String] = []
    private(set) var errorMessages: [String] = []

    func debug(_ message: String) {
        debugMessages.append(message)
    }

    func info(_ message: String) {
        infoMessages.append(message)
    }

    func error(_ message: String) {
        errorMessages.append(message)
    }
}
