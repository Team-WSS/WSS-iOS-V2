//
//  Project.swift
//  Manifests
//
//  Created by Guryss on 8/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createFeatureModule(
    name: ModuleType.feature(.collection).name,
    targets: [.sources, .demo, .tests],
    internalDependencies: [
        .module(.domain(.base)),
        .module(.domain(.collection)),
        // "작품 추가" 화면(SearchNovelUseCase)용 — FeedFeature의 연결 작품 검색과 같은 이유.
        .module(.domain(.search)),
        // "서재에서 추가" 화면(LoadMyLibraryUseCase·LibraryNovel·MyLibraryFilter)용 — 서재 Domain
        // 코드는 별도 모듈이 아니라 NovelDomain에 있다(LibraryFeature와 같은 이유).
        .module(.domain(.novel)),
        .module(.ui(.designSystem)),
        .module(.ui(.wssComponent)),
        .module(.core(.logger))
    ],
    // Demo 앱만 실서버 조립을 위해 Data/Networking을 의존한다(App의 DI 역할 대행).
    // Sources는 여전히 Data를 모른다 — Feature 레이어 규칙 유지.
    demoDependencies: [
        .module(.data(.collection)),
        .module(.data(.search)),
        .module(.data(.novel)),
        .module(.data(.base)),
        .module(.core(.networking))
    ]
)
