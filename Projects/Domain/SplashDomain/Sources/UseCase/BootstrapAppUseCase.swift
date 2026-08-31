//
//  BootstrapAppUseCase.swift
//  SplashDomain
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

/// 런치 부트스트랩 — 앱 진입 시 게이트 판정과 부수 태스크 실행을 한곳에서 수행한다.
///
/// 정책(순서·실패 분기)은 이 UseCase가 전담한다:
/// 1. 강제 업데이트 게이트 — 조회 **실패는 통과**시킨다(서버 장애가 앱을 잠그면 안 된다).
/// 2. 세션 게이트 — 저장된 세션이 없으면 인트로로, 부수 태스크는 시작하지 않는다.
/// 3. 부수 태스크 4종(users/me·FCM·키워드·프리페치) — **던지고 진입**(완료를 기다리지 않고,
///    실패·지연이 앱 진입을 막지 않는다).
/// 4. 약관 게이트 — 조회 실패는 동의로 간주해 진입을 막지 않는다. 단 세션 소실만은 인트로로.
///
/// **"실패는 통과"는 응답이 돌아와야 작동한다** — 그래서 게이트마다 예산(`gateBudget`)을 걸고,
/// 예산을 넘기면 판정 불가로 보고 통과시킨다. 예산이 없으면 `URLSession` 기본 타임아웃(60초)에
/// 맡기게 돼, 반쯤 연결된 망(호텔 wifi·약전계)에서 스플래시가 최대 2분 잠긴다.
public protocol BootstrapAppUseCase: Sendable {
    func execute() async -> BootstrapOutcome
}

public final class DefaultBootstrapAppUseCase: BootstrapAppUseCase {

    /// **부트스트랩 전체**가 게이트 응답을 기다리는 상한(게이트당이 아니다).
    /// 스플래시 최소 노출(1초)보다 넉넉하되, 넘기면 사용자가 "앱이 멈췄다"고 느끼기 시작하는 구간 앞에서 끊는다.
    /// (`public`인 건 `init`의 기본 인자로 쓰기 위함 — 기본값은 호출자 쪽에서 평가된다.)
    public static let defaultGateBudget: Duration = .seconds(4)

    private let gateRepository: LaunchGateRepository
    private let taskRepository: LaunchTaskRepository
    private let gateBudget: Duration
    /// 부수 태스크를 "던지고 가는" 실행 시임(seam) — 프로덕션은 기본값(`Task`)을 쓰고,
    /// 테스트는 작업을 붙잡아 두는 스파이를 주입해 fire-and-forget을 결정적으로 검증한다.
    private let launchInBackground: @Sendable (@escaping @Sendable () async -> Void) -> Void
    /// 예산 타이머 시임(seam) — 테스트는 즉시 끝나는 타이머를 주입해 실시간 대기 없이
    /// 타임아웃 경로를 탄다. 프로덕션은 기본값(`Task.sleep`)을 쓴다.
    private let waitGateBudget: @Sendable (Duration) async -> Void

    public init(
        gateRepository: LaunchGateRepository,
        taskRepository: LaunchTaskRepository,
        gateBudget: Duration = DefaultBootstrapAppUseCase.defaultGateBudget,
        launchInBackground: @escaping @Sendable (@escaping @Sendable () async -> Void) -> Void = { work in
            Task { await work() }
        },
        waitGateBudget: @escaping @Sendable (Duration) async -> Void = { budget in
            try? await Task.sleep(for: budget)
        }
    ) {
        self.gateRepository = gateRepository
        self.taskRepository = taskRepository
        self.gateBudget = gateBudget
        self.launchInBackground = launchInBackground
        self.waitGateBudget = waitGateBudget
    }

    public func execute() async -> BootstrapOutcome {
        // 예산은 **게이트마다가 아니라 부트스트랩 전체에 한 번** 준다 — 게이트별로 주면 최악 대기가
        // 게이트 수만큼 곱해져(2개면 8초) 스플래시가 그만큼 잠긴다. 두 게이트가 이 마감을 나눠 쓴다.
        let deadline = ContinuousClock.now.advanced(by: gateBudget)

        // 1. 강제 업데이트 게이트 — 세션 유무와 무관하게 최우선.
        //    조회 실패도 예산 초과도 통과(판정할 수 없으면 막지 않는다).
        let forceUpdate = await withinBudget(until: deadline) { [self] in await loadForceUpdateRequired() }
        if case .success(true) = forceUpdate { return .forceUpdate }

        // 2. 세션 게이트 — 없으면 인트로로, 부수 태스크는 시작하지 않는다.
        guard gateRepository.hasValidSession() else { return .intro }

        // 3. 부수 태스크 4종 — 던지고 진입(실패·지연이 앱 진입을 막지 않는다).
        let taskRepository = taskRepository
        launchInBackground {
            async let userSync: Void? = try? taskRepository.syncUserBasicInfo()
            async let deviceToken: Void? = try? taskRepository.registerDeviceTokenIfNeeded()
            async let keywords: Void = taskRepository.syncKeywords()
            async let prefetch: Void = taskRepository.prefetchHomeData()
            _ = await (userSync, deviceToken, keywords, prefetch)
        }

        // 4. 약관 게이트 — 조회 실패·예산 초과는 동의로 간주해 진입을 막지 않는다.
        let terms = await withinBudget(until: deadline) { [self] in await loadTermsAgreed() }
        switch terms {
        case .success(let agreed):
            return .main(needsTermsAgreement: !agreed)
        case .failure(.authenticationRequired):
            // 세션이 소실된 상태 — main으로 보내면 메인 탭이 401을 맞고 온보딩으로 되돌려
            // 화면이 번쩍인다. 여기서 인트로로 낙착시켜 그 왕복을 없앤다(사용자 확정, #225).
            return .intro
        case .failure, .none:
            return .main(needsTermsAgreement: false)
        }
    }
}

// MARK: - Gate Budget

private extension DefaultBootstrapAppUseCase {

    /// 게이트 호출을 `Result`로 감싼다. do/catch를 **함수 본문**에 두는 게 핵심 —
    /// 클로저 리터럴 안에서는 typed throws가 `any Error`로 넓어져 컴파일되지 않는다.
    func loadForceUpdateRequired() async -> Result<Bool, RepositoryError> {
        do { return .success(try await gateRepository.checkForceUpdateRequired()) }
        catch { return .failure(error) }
    }

    func loadTermsAgreed() async -> Result<Bool, RepositoryError> {
        do { return .success(try await gateRepository.isRequiredTermsAgreed()) }
        catch { return .failure(error) }
    }

    /// 게이트 호출을 **공유 마감(`deadline`)까지** 기다린다. 넘기면 `nil` —
    /// 호출자는 `nil`과 `.failure`를 똑같이 "판정 불가 → 통과"로 다룬다.
    /// 앞 게이트가 예산을 다 썼으면 뒤 게이트는 기다리지 않고 곧장 `nil`이 된다.
    ///
    /// 예산이 먼저 끝나면 그룹을 취소해 매달린 요청도 함께 푼다.
    ///
    /// ⚠️ **이건 하드 타임아웃이 아니라 "게이트가 취소에 반응한다"는 전제 위의 예산이다** —
    /// `withTaskGroup`은 `cancelAll()` 뒤에도 자식이 실제로 끝나야 스코프를 빠져나간다.
    /// 현재 두 게이트는 `URLSession`을 타므로 취소에 반응하지만, **취소를 무시하는 대기**
    /// (아무도 resume하지 않는 `withCheckedContinuation`, 취소 비협조 SDK)를 게이트 구현에
    /// 끼워 넣으면 예산이 무력해지고 스플래시가 그대로 잠긴다.
    func withinBudget<T: Sendable>(
        until deadline: ContinuousClock.Instant,
        _ operation: @escaping @Sendable () async -> Result<T, RepositoryError>
    ) async -> Result<T, RepositoryError>? {
        let remaining = ContinuousClock.now.duration(to: deadline)
        guard remaining > .zero else { return nil }

        return await withTaskGroup(of: Result<T, RepositoryError>?.self) { group in
            group.addTask { await operation() }
            group.addTask { [waitGateBudget] in
                await waitGateBudget(remaining)
                return nil
            }

            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }
}
