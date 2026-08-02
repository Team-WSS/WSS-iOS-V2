//
//  OnboardingFeatureDemoApp.swift
//  OnboardingFeatureDemo
//
//  Created by Seoyeon Choi on 8/2/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import KakaoSDKCommon

import OnboardingFeature
import AuthDomain
import BaseData
import AuthData
import Logger
import Networking
import DesignSystem

@main
struct OnboardingFeatureDemoApp: App {
    init() {
        // 커스텀 폰트(Pretendard) 등록. 없으면 applyWSSFont의 UIFont(name:)! 가 nil → 크래시.
        DesignSystemFontFamily.registerAllCustomFonts()

        // 카카오 로그인 버튼을 이 Demo 앱 단독으로 테스트하려면 실행 시 한 번 초기화가 필요하다
        // (App은 Demo와 별개 프로세스라 App의 초기화를 못 물려받는다).
        if let kakaoAppKey = Bundle.main.infoDictionary?["KAKAO_APP_KEY"] as? String, !kakaoAppKey.isEmpty {
            KakaoSDK.initSDK(appKey: kakaoAppKey)
        } else {
            assertionFailure("KAKAO_APP_KEY가 Info.plist에 없습니다.")
        }
    }

    var body: some Scene {
        WindowGroup {
            DemoRootView()
        }
    }
}

// MARK: - Root: Mock ↔ 실서버 토글

// Demo가 App(DI) 역할을 대행해 UseCase를 조립한다.
// Mock = 인메모리(흐름 시연, SDK 로그인은 실제로 뜸), 실서버 = NetworkingClient + 실제 Repository.
private struct DemoRootView: View {
    private enum DataSource: String, CaseIterable, Identifiable {
        case mock = "Mock"
        case live = "실서버"
        var id: String { rawValue }
    }

    @State private var dataSource: DataSource = .live

    /// Demo 전 계층(Feature/Repository/Networking)에 주입할 콘솔 로거. 한 인스턴스를 공유한다.
    private let consoleLogger = ConsoleLogger()

    var body: some View {
        // 데이터 소스 Picker는 숨김 — 실제 화면을 프로덕션과 동일하게 풀스크린으로 보기 위함.
        // 전환 로직 자체는 남아있다(현재 기본값 .live/실서버) — Mock(인메모리)으로 보려면 위 dataSource 기본값을 .mock으로 바꾸면 된다.
        NavigationStack {
            introView
                .toolbar(.hidden, for: .navigationBar)
        }
    }

    @ViewBuilder
    private var introView: some View {
        switch dataSource {
        case .mock:
            OnboardingFactory.makeIntroView(
                socialLoginUseCase: DemoSocialLoginUseCase(),
                logger: consoleLogger,
                onLoginSucceeded: handleLoginSucceeded,
                onContinueWithoutSignIn: handleContinueWithoutSignIn
            )
        case .live:
            makeLiveView()
        }
    }

    // MARK: - 실서버 조립

    // NetworkingConfig.baseURL로 호출. 로그인 자체는 .withoutToken 엔드포인트라 DemoSessionTokenStore로 충분하고,
    // 로그인 성공으로 발급된 토큰은 DefaultTokenStore(Keychain)에 실제로 저장된다.
    @MainActor
    private func makeLiveView() -> some View {
        let client = NetworkingClient(
            logger: DefaultNetworkLogger(base: consoleLogger),
            tokenStore: DemoSessionTokenStore()
        )
        let repository = AuthDataFactory.makeRepository(
            client: client,
            tokenStore: DefaultTokenStore(),
            deviceIdentifierStore: DefaultDeviceIdentifierStore(),
            logger: DataLogger(moduleName: "AuthData", underlying: consoleLogger)
        )
        return OnboardingFactory.makeIntroView(
            socialLoginUseCase: DefaultSocialLoginUseCase(authRepository: repository),
            logger: consoleLogger,
            onLoginSucceeded: handleLoginSucceeded,
            onContinueWithoutSignIn: handleContinueWithoutSignIn
        )
    }

    private func handleLoginSucceeded(_ needOnboarding: NeedOnboarding) {
        consoleLogger.info("로그인 성공 → NeedOnboarding: \(needOnboarding.value)")
    }

    private func handleContinueWithoutSignIn() {
        consoleLogger.info("회원가입 없이 둘러보기 탭됨")
    }
}

// MARK: - Demo UseCase (Mock)
// 인메모리 Mock으로 흐름만 시연한다(서버 불필요) — SDK 로그인 자체(Apple/Kakao)는 실제로 동작한다.

private struct DemoSocialLoginUseCase: SocialLoginUseCase {
    func execute(credential: SocialLoginCredential) async throws(AuthError) -> NeedOnboarding {
        try? await Task.sleep(nanoseconds: 500_000_000)
        return NeedOnboarding(value: true)
    }
}
