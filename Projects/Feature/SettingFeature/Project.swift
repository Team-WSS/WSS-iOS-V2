//
//  Project.swift
//  Manifests
//
//  Created by Seoyeon Choi on 7/15/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createFeatureModule(
    name: ModuleType.feature(.setting).name,
    targets: [.sources, .demo],
    internalDependencies: [
        .module(.domain(.base)),
        .module(.domain(.profile)),
        .module(.domain(.notification)),
        .module(.domain(.social)),
        .module(.domain(.auth)),
        .module(.domain(.novel)),
        .module(.ui(.designSystem)),
        .module(.ui(.wssComponent)),
        .module(.core(.logger)),
        .module(.core(.pushAuthorization))
    ],
    // Demo 앱만 실서버 조립을 위해 Data/Networking을 의존한다(App의 DI 역할 대행).
    // Sources는 여전히 Data를 모른다 — Feature 레이어 규칙 유지.
    demoDependencies: [
        .module(.data(.profile)),
        .module(.data(.notification)),
        .module(.data(.social)),
        .module(.data(.auth)),
        .module(.data(.novel)),
        .module(.data(.base)),
        .module(.core(.networking))
    ]
)
