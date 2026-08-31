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
/// 4. 약관 게이트 — 조회 실패는 동의로 간주해 진입을 막지 않는다.
public protocol BootstrapAppUseCase: Sendable {
    func execute() async -> BootstrapOutcome
}

public final class DefaultBootstrapAppUseCase: BootstrapAppUseCase {
    private let gateRepository: LaunchGateRepository
    private let taskRepository: LaunchTaskRepository
    /// 부수 태스크를 "던지고 가는" 실행 시임(seam) — 프로덕션은 기본값(`Task`)을 쓰고,
    /// 테스트는 작업을 붙잡아 두는 스파이를 주입해 fire-and-forget을 결정적으로 검증한다.
    private let launchInBackground: @Sendable (@escaping @Sendable () async -> Void) -> Void

    public init(
        gateRepository: LaunchGateRepository,
        taskRepository: LaunchTaskRepository,
        launchInBackground: @escaping @Sendable (@escaping @Sendable () async -> Void) -> Void = { work in
            Task { await work() }
        }
    ) {
        self.gateRepository = gateRepository
        self.taskRepository = taskRepository
        self.launchInBackground = launchInBackground
    }

    public func execute() async -> BootstrapOutcome {
        // 1. 강제 업데이트 게이트 — 세션 유무와 무관하게 최우선. 조회 실패는 통과.
        if (try? await gateRepository.checkForceUpdateRequired()) == true {
            return .forceUpdate
        }

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

        // 4. 약관 게이트 — 조회 실패는 동의로 간주해 진입을 막지 않는다.
        let agreed = (try? await gateRepository.isRequiredTermsAgreed()) ?? true
        return .main(needsTermsAgreement: !agreed)
    }
}
