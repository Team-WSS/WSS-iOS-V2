//
//  Project.swift
//  Manifests
//
//  Created by YunhakLee on 6/4/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createFeatureModule(
    name: ModuleType.feature(.novelReview).name,
    targets: [.sources, .demo, .tests],
    internalDependencies: [
        .module(.domain(.base)),
        .module(.domain(.novelReview)),
        .module(.ui(.designSystem)),
        .module(.ui(.wssComponent)),
        .module(.core(.logger))
    ],
    // Demo 앱만 실서버 조립을 위해 Data/Networking을 의존한다(App의 DI 역할 대행).
    // Sources는 여전히 Data를 모른다 — Feature 레이어 규칙 유지.
    demoDependencies: [
        .module(.data(.novelReview)),
        .module(.data(.base)),
        .module(.core(.networking))
    ],
    // ViewModel 테스트가 NovelReviewDomainTesting의 공유 Mock UseCase를 import 하게 한다
    // (Mock UseCase는 UseCase 프로토콜이 선언된 Domain의 Testing 타깃에 둔다 — Repository Mock과 같은 자리).
    testDependencies: [
        .module(.domain(.novelReview), type: .testing)
    ]
)
