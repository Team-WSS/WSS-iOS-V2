//
//  Project.swift
//  Manifests
//
//  Created by Seoyeon Choi on 7/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createFeatureModule(
    name: ModuleType.feature(.search).name,
    targets: [.sources, .demo],
    internalDependencies: [
        .module(.domain(.base)),
        .module(.domain(.recommendation)),
        .module(.domain(.search)),
        .module(.ui(.designSystem)),
        .module(.ui(.wssComponent)),
        .module(.core(.logger))
    ],
    demoDependencies: [
        // #185: 상세탐색 필터 화면의 "키워드" 탭 콘텐츠(KeywordTabContentBuilder)를 실제로 조립하려면
        // KeywordFeature가 필요하다(Feature 간 직접 의존 금지 — Sources는 여전히 KeywordFeature를 모른다,
        // Demo만 App 역할 대행으로 의존).
        .module(.feature(.keyword)),
        .module(.data(.recommendation)),
        .module(.data(.search)),
        .module(.data(.base)),
        .module(.core(.networking))
    ]
)
