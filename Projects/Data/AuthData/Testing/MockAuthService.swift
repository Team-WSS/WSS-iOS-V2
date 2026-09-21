@testable import AuthData

final class MockAuthService: AuthService {

    var postAppleLoginResult: Result<LoginSuccessResponse, Error>!
    var postKakaoLoginResult: Result<LoginSuccessResponse, Error>!
    var patchAppleAccountSyncResult: Result<Void, Error> = .success(())
    var postLogoutResult: Result<Void, Error> = .success(())
    var postWithdrawResult: Result<Void, Error> = .success(())

    private(set) var requestedAppleLogin: AppleLoginRequest?
    private(set) var requestedKakaoLoginHeader: KakaoLoginRequestHeader?
    private(set) var requestedAppleSync: AppleSyncRequest?
    private(set) var requestedLogout: LogoutRequest?
    private(set) var requestedWithdraw: WithdrawRequest?

    func postAppleLogin(_ request: AppleLoginRequest) async throws -> LoginSuccessResponse {
        requestedAppleLogin = request
        return try postAppleLoginResult.get()
    }

    func postKakaoLogin(_ requestHeader: KakaoLoginRequestHeader) async throws -> LoginSuccessResponse {
        requestedKakaoLoginHeader = requestHeader
        return try postKakaoLoginResult.get()
    }

    func patchAppleAccountSync(_ request: AppleSyncRequest) async throws {
        requestedAppleSync = request
        return try patchAppleAccountSyncResult.get()
    }

    func postLogout(_ request: LogoutRequest) async throws {
        requestedLogout = request
        return try postLogoutResult.get()
    }

    func postWithdraw(_ request: WithdrawRequest) async throws {
        requestedWithdraw = request
        return try postWithdrawResult.get()
    }

    func postReissueToken(_ request: ReissueRequest) async throws -> ReissueResponse {
        fatalError("not implemented")
    }
}
