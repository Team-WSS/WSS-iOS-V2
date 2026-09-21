//
//  Project.swift
//  Manifests
//
//  Created by Seoyeon Choi on 7/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createFeatureModule(
    name: ModuleType.feature(.keyword).name,
    targets: [.sources, .demo],
    internalDependencies: [
        .module(.domain(.base)),
        .module(.ui(.designSystem)),
        .module(.ui(.wssComponent)),
        .module(.core(.logger))
    ],
    // Demo 앱만 실서버 조립을 위해 Data/Networking을 의존한다(App의 DI 역할 대행).
    // Sources는 여전히 Data를 모른다 — Feature 레이어 규칙 유지.
    demoDependencies: [
        .module(.data(.base)),
        .module(.core(.logger)),
        .module(.core(.networking))
    ]
)
