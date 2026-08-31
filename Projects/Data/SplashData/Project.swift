//
//  Project.swift
//  AppManifests
//
//  Created by YunhakLee on 8/31/26.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

// SplashDomain의 두 포트(LaunchGate/LaunchTask)를 구현하는 composite 모듈 —
// 자기 네트워크 호출 없이 다른 도메인들의 Repository "프로토콜"에 위임만 한다.
// 그래서 표준 Data 의존(BaseData·Logger)과 Demo·Testing 타깃이 없다:
// DTO/Mapper/Service가 없고, Mock은 SplashDomainTesting(포트 쪽)이 담당한다.
let project = Project.createDataModule(
    name: ModuleType.data(.splash).name,
    targets: [.sources, .tests],
    internalDependencies: [
        .module(.core(.networking)),          // SessionTokenStore(세션 유무)
        .module(.domain(.base)),              // RepositoryError·KeywordRepository
        .module(.domain(.splash)),            // 구현 대상 포트
        .module(.domain(.profile)),           // ProfileRepository(users/me)
        .module(.domain(.setting)),           // AppUpdate·TermsAgreement
        .module(.domain(.notification)),      // PushSettingRepository(디바이스 토큰)
        .module(.domain(.recommendation))     // RecommendationRepository·HomePrefetchStore
    ],
    // 위임 검증 테스트가 각 도메인의 기존 Mock을 재사용한다.
    testDependencies: [
        .module(.domain(.base), type: .testing),
        .module(.domain(.profile), type: .testing),
        .module(.domain(.setting), type: .testing),
        .module(.domain(.notification), type: .testing),
        .module(.domain(.recommendation), type: .testing)
    ]
)
