@testable import AuthData

final class MockAuthService: AuthService {

    var postAppleLoginResult: Result<LoginSuccessResponse, Error>!
    var postKakaoLoginResult: Result<LoginSuccessResponse, Error>!

    private(set) var requestedAppleLogin: AppleLoginRequest?
    private(set) var requestedKakaoLoginHeader: KakaoLoginRequestHeader?

    func postAppleLogin(_ request: AppleLoginRequest) async throws -> LoginSuccessResponse {
        requestedAppleLogin = request
        return try postAppleLoginResult.get()
    }

    func postKakaoLogin(_ requestHeader: KakaoLoginRequestHeader) async throws -> LoginSuccessResponse {
        requestedKakaoLoginHeader = requestHeader
        return try postKakaoLoginResult.get()
    }

    func patchAppleAccountSync(_ request: AppleSyncRequest) async throws { }
    func postLogout(_ request: LogoutRequest) async throws { }
    func postWithdraw(_ request: WithdrawRequest) async throws { }
    func postReissueToken(_ request: ReissueRequest) async throws -> ReissueResponse {
        fatalError("not implemented")
    }
}
