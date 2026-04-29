import Testing
@testable import AuthData
@testable import AuthDataTesting
import AuthDomain
import BaseDomain
import Networking

@Suite("DefaultAuthRepository")
struct DefaultAuthRepositoryTests {

    // MARK: - Helpers

    private func makeRepository(
        service: MockAuthService = MockAuthService(),
        tokenStore: MockTokenStore = MockTokenStore()
    ) -> DefaultAuthRepository {
        DefaultAuthRepository(
            service: service,
            tokenStore: tokenStore,
            deviceIdentifierStore: MockDeviceIdentifierStore(),
            logger: nil
        )
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
            (.unknown, .networkUnavailable),
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
}
