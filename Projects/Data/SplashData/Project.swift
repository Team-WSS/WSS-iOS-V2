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
// 그래서 표준 Data 구성(DTO/Mapper/Service·Demo)이 없다. 단 BaseData는 예외로 의존한다 —
// 게이트가 로컬 저장소(AppStorage·StorageKey.isRegistered, #257)를 SessionTokenStore와 같은 결로
// 직접 조회하기 때문(위임 전용 원칙의 유일한 로컬-읽기 예외).
let project = Project.createDataModule(
    name: ModuleType.data(.splash).name,
    targets: [.sources, .tests],
    internalDependencies: [
        .module(.core(.networking)),          // SessionTokenStore(세션 유무)
        .module(.domain(.base)),              // RepositoryError·KeywordRepository
        .module(.data(.base)),                // AppStorage·StorageKey.isRegistered(온보딩 완료 여부, #257)
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
