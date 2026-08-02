//
//  Project.swift
//  Manifests
//
//  Created by Seoyeon Choi on 8/2/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createFeatureModule(
    name: ModuleType.feature(.onboarding).name,
    targets: [.sources, .demo],
    // 전용 OnboardingDomain은 없다 — 이번 이슈 범위(인트로+소셜로그인 화면)는 AuthDomain의
    // SocialLoginUseCase를 그대로 재사용한다. 가입약관 시트·닉네임·성별/출생년도·장르 선택(ProfileDomain
    // 의존)은 후속 이슈에서 이어간다 — 그때 domain(.profile)/data(.profile)을 추가한다.
    internalDependencies: [
        .module(.domain(.base)),
        .module(.domain(.auth)),
        .module(.ui(.designSystem)),
        .module(.ui(.wssComponent)),
        .module(.core(.logger)),
        // 인트로 화면의 카카오 로그인 버튼이 UserApi.shared.loginWithKakaoAccount(...)를 직접 호출한다.
        // OAuthToken 타입 때문에 KakaoSDKAuth도 필요.
        .external(name: "KakaoSDKUser"),
        .external(name: "KakaoSDKAuth")
    ],
    // Demo 앱만 실서버 조립을 위해 Data/Networking을 의존한다(App의 DI 역할 대행).
    // Sources는 여전히 Data를 모른다 — Feature 레이어 규칙 유지.
    demoDependencies: [
        .module(.data(.auth)),
        .module(.data(.base)),
        .module(.core(.networking)),
        // Demo 앱 자체 진입점에서 KakaoSDK.initSDK(appKey:)를 호출해야 한다(App 조립을 Demo가 대행).
        .external(name: "KakaoSDKCommon")
    ],
    // Apple 로그인(SignInWithAppleButton) capability. 없으면 인증 시도 시 실패한다.
    demoEntitlements: .file(path: "Demo/OnboardingFeatureDemo.entitlements")
)
