//
//  SplashViewModel.swift
//  SplashFeature
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Observation

import SplashDomain

@MainActor
@Observable
final class SplashViewModel {

    // MARK: - State
    struct State {
        /// 부트스트랩 완료 결과. 세팅되면 View가 onFinish로 App에 올려 라우팅한다(이 화면은 전환하지 않음).
        var outcome: BootstrapOutcome?
    }

    // MARK: - Action
    enum Action { case load }

    // MARK: - Output
    private(set) var state = State()

    // MARK: - Property
    // internal 노출은 테스트용 — 완료 시점을 폴링 없이 결정적으로 기다린다(`await bootstrapTask?.value`).
    @ObservationIgnored private(set) var bootstrapTask: Task<Void, Never>?

    // MARK: - Dependency
    /// 최소 노출 시간 대기 시임(seam) — 프로덕션은 기본값(1.0초, V1 체감 유지)을 쓰고,
    /// 테스트만 대기를 붙잡는 fake를 주입해 "둘 다 끝나야 완료"를 결정적으로 검증한다.
    ///
    /// ⚠️ **1.0초라는 값 자체는 테스트가 못 지킨다** — 모든 테스트가 이 시임을 주입하므로
    /// 기본값을 0초로 바꿔도 전부 초록이다. 값 변경은 리뷰로만 걸러진다.
    private let waitMinimumDisplayTime: @Sendable () async -> Void

    // SplashDomain
    private let bootstrapAppUseCase: BootstrapAppUseCase

    // MARK: - Init
    init(
        bootstrapAppUseCase: BootstrapAppUseCase,
        waitMinimumDisplayTime: @escaping @Sendable () async -> Void = {
            try? await Task.sleep(for: .seconds(1))
        }
    ) {
        self.bootstrapAppUseCase = bootstrapAppUseCase
        self.waitMinimumDisplayTime = waitMinimumDisplayTime
    }

    // MARK: - handle
    func handle(_ action: Action) {
        switch action {
        case .load: load()
        }
    }
}

// MARK: - Action Handling
private extension SplashViewModel {

    func load() {
        // onAppear 중복 발화 가드 — 부트스트랩은 앱 런치당 한 번이다.
        guard bootstrapTask == nil else { return }

        bootstrapTask = Task { await bootstrap() }
    }
}

// MARK: - UseCase Handling
private extension SplashViewModel {

    /// 부트스트랩과 최소 노출 타이머를 병렬로 돌리고, 둘 다 끝나야 완료를 알린다 —
    /// 빨라도 스플래시가 깜빡 사라지지 않고, 느려도 추가 지연이 없다.
    ///
    /// ⚠️ 취소 재확인이 없는 건 의도다 — 이 VM에는 cancel 경로가 없고, 스플래시는 outcome이
    /// 나올 때까지 화면에 붙어 있는 게 계약이라 덮어쓸 stale 상태가 없다. 다만 나중에
    /// `bootstrapTask.cancel()`을 배선한다면, 기본 시임의 `try? await Task.sleep`이
    /// `CancellationError`를 삼켜 **취소 = 즉시 완료**로 동작한다는 걸 함께 봐야 한다.
    func bootstrap() async {
        async let bootstrapOutcome = bootstrapAppUseCase.execute()
        async let minimumDisplay: Void = waitMinimumDisplayTime()

        let outcome = await bootstrapOutcome
        await minimumDisplay

        state.outcome = outcome
    }
}
