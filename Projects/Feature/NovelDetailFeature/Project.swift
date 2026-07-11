//
//  Project.swift
//  Manifests
//
//  Created by YunhakLee on 7/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createFeatureModule(
    name: ModuleType.feature(.novelDetail).name,
    targets: [.sources, .demo, .tests],
    // 전용 NovelDetailDomain은 없다 — 소설 상세는 NovelDomain의 UseCase를 쓴다(#154).
    // 피드 탭이 이슈 범위에 포함되어 FeedDomain(LoadNovelFeedsUseCase)도,
    // 평가 삭제가 포함되어 NovelReviewDomain(DeleteNovelReviewUseCase)도 의존한다.
    internalDependencies: [
        .module(.domain(.base)),
        .module(.domain(.novel)),
        .module(.domain(.feed)),
        .module(.domain(.novelReview)),
        .module(.ui(.designSystem)),
        .module(.ui(.wssComponent)),
        .module(.core(.logger))
    ],
    // Demo 앱만 실서버 조립을 위해 Data/Networking을 의존한다(App의 DI 역할 대행).
    // Sources는 여전히 Data를 모른다 — Feature 레이어 규칙 유지.
    demoDependencies: [
        .module(.data(.novel)),
        .module(.data(.feed)),
        .module(.data(.novelReview)),
        .module(.data(.base)),
        .module(.core(.networking))
    ]
)
