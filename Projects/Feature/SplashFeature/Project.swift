//
//  Project.swift
//  Manifests
//
//  Created by YunhakLee on 8/31/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createFeatureModule(
    name: ModuleType.feature(.splash).name,
    targets: [.sources, .demo, .tests],
    // WSSComponent·Logger 의도적 제외 — 스플래시는 DesignSystem 에셋 3장만 그리고,
    // VM에 실패 경로가 없다(BootstrapAppUseCase는 non-throwing, 태스크 실패 로깅은 Data 레이어 몫).
    internalDependencies: [
        .module(.domain(.base)),
        .module(.domain(.splash)),
        .module(.ui(.designSystem))
    ],
    // Demo는 실서버 조립 대신 Mock 시나리오 방식 — SplashData 실서버 조립은 도메인 6종의
    // Repository 인스턴스가 전부 필요해 사실상 App 전체 DI 복제라 Demo 목적(화면·분기 확인)에 과하다.
    demoDependencies: [
        .module(.domain(.splash), type: .testing)
    ],
    // ViewModel 테스트가 SplashDomainTesting의 공유 Mock UseCase를 import 하게 한다.
    testDependencies: [
        .module(.domain(.splash), type: .testing)
    ]
)
