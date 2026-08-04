//
//  Project.swift
//  Manifests
//
//  Created by YunhakLee on 8/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createFeatureModule(
    name: ModuleType.feature(.home).name,
    targets: [.sources, .demo, .tests],
    // 홈의 Domain 코드(LoadHomeDataUseCase·HomeData·TodayDiscovery 등)는 별도 HomeDomain이 아니라
    // RecommendationDomain에 있다 → 같은이름 규칙 대신 RecommendationDomain을 의존한다.
    internalDependencies: [
        .module(.domain(.base)),
        .module(.domain(.recommendation)),
        .module(.ui(.designSystem)),
        .module(.ui(.wssComponent)),
        .module(.core(.logger))
    ],
    // Demo 앱만 실서버 조립을 위해 Data/Networking을 의존한다(App의 DI 역할 대행).
    // Sources는 여전히 Data를 모른다 — Feature 레이어 규칙 유지.
    demoDependencies: [
        .module(.data(.recommendation)),
        .module(.data(.base)),
        .module(.core(.networking))
    ]
)
