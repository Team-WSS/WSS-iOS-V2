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
    targets: [.sources, .demo, .tests],
    // 전용 OnboardingDomain은 없다 — 닉네임/성별/출생년도/장르 등록은 ProfileDomain의
    // RegisterProfileUseCase(ProfileRegistration)를 그대로 재사용한다(소개 슬라이드·권한 요청은
    // 도메인 UseCase가 필요 없는 순수 UI/시스템 API 화면).
    internalDependencies: [
        .module(.domain(.base)),
        .module(.domain(.profile)),
        .module(.ui(.designSystem)),
        .module(.ui(.wssComponent)),
        .module(.core(.logger))
    ],
    // Demo 앱만 실서버 조립을 위해 Data/Networking을 의존한다(App의 DI 역할 대행).
    // Sources는 여전히 Data를 모른다 — Feature 레이어 규칙 유지.
    demoDependencies: [
        .module(.data(.profile)),
        .module(.data(.base)),
        .module(.core(.networking))
    ]
)
