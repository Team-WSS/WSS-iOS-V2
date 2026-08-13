//
//  SessionRefreshCoordinator.swift
//  Networking
//
//  Created by YunhakLee on 8/13/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

enum SessionRefreshResult {
    /// 이 호출이(또는 함께 기다린 호출이) 갱신에 성공했다 → 재시도 가능
    case refreshed
    /// 내 토큰만 낡았을 뿐 이미 갱신되어 있었다 → 재발급 없이 재시도 가능
    case alreadyRefreshed
    /// 세션이 종료됐다 → 재인증 필요
    case sessionExpired
}

/// 401 재인증을 직렬화한다.
///
/// 서버가 refresh token을 회전시키므로 재발급이 동시에 두 번 나가면
/// 나중 것이 폐기된 토큰을 쓰게 되어 세션 전체가 끊긴다. 이를 두 겹으로 막는다.
/// 1. 진행 중인 재발급이 있으면 새로 시작하지 않고 그 결과를 함께 기다린다.
/// 2. 요청이 쓴 access token이 이미 낡았다면 재발급 없이 곧바로 재시도시킨다.
actor SessionRefreshCoordinator {
    private let refresher: AuthSessionRefreshing
    private let tokenStore: SessionTokenStore?

    private var inFlight: Task<SessionRefreshResult, Error>?

    init(
        refresher: AuthSessionRefreshing,
        tokenStore: SessionTokenStore?
    ) {
        self.refresher = refresher
        self.tokenStore = tokenStore
    }

    func refresh(usedAccessToken: String?) async throws -> SessionRefreshResult {
        // ⚠️ 여기부터 `inFlight` 저장까지는 반드시 동기여야 한다.
        //    중간에 await가 끼면 두 호출이 모두 nil을 보고 각자 재발급을 시작한다.
        if isAlreadyRefreshed(comparedTo: usedAccessToken) {
            return .alreadyRefreshed
        }

        let task = inFlight ?? startRefresh()

        return try await task.value
    }
}

private extension SessionRefreshCoordinator {

    /// 내가 보낸 토큰이 지금 저장된 것과 다르다 = 그 사이 누군가 갱신했다.
    func isAlreadyRefreshed(comparedTo usedAccessToken: String?) -> Bool {
        guard let usedAccessToken,
              let current = currentAccessToken(),
              current.isEmpty == false else {
            return false
        }

        return current != usedAccessToken
    }

    func currentAccessToken() -> String? {
        guard let tokenStore else { return nil }
        return try? tokenStore.accessToken()
    }

    /// `Task {}`는 이 actor의 격리를 물려받으므로 내부에서 상태를 동기로 만질 수 있고,
    /// unstructured라 대기자 하나가 취소돼도 공유 갱신이 죽지 않는다 (의도적 선택).
    func startRefresh() -> Task<SessionRefreshResult, Error> {
        let task = Task { () async throws -> SessionRefreshResult in
            // `inFlight`는 여기서만 비워지므로 남의 Task를 지울 수 없다.
            // 정리를 대기자 쪽으로 옮기면 세대 비교 가드가 필요해진다.
            defer { self.inFlight = nil }

            do {
                let didRefresh = try await self.refresher.refreshSession()

                guard didRefresh else {
                    self.clearTokens()
                    return .sessionExpired
                }

                return .refreshed
            } catch let error as NetworkingError where error.indicatesExpiredSession {
                self.clearTokens()
                return .sessionExpired
            }
            // 그 밖의 에러(통신 실패 등)는 그대로 던진다 → 토큰을 보존한다.
        }

        inFlight = task
        return task
    }

    func clearTokens() {
        try? tokenStore?.clearTokens()
    }
}

private extension NetworkingError {

    /// 서버가 refresh token 자체를 거절한 경우(401)만 세션 종료로 본다.
    /// 400·404 같은 요청·배포 문제나 통신 실패는 세션 상태를 알려주지 않으므로,
    /// 토큰을 지우지 말고 에러를 그대로 전파해야 한다.
    var indicatesExpiredSession: Bool {
        guard case .responseFailure(let code, _) = self else { return false }
        return code == 401
    }
}
