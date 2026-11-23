//
//  Package.swift
//  AppManifests
//
//  Created by YunhakLee on 10/21/25.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createDomainModule(
    name: ModuleType.domain(.profile).name,
    targets: [.sources, .testing, .tests],
    internalDependencies: [.module(.domain(.base))],
    // 선호 작품 불러오기 테스트가 BaseDomain의 MockLoadTotalKeywordsUseCase를 쓴다.
    testDependencies: [.module(.domain(.base), type: .testing)]
)
