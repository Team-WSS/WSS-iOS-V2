//
//  Project.swift
//  AppManifests
//
//  Created by Seoyeon Choi on 2/9/26.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createDomainModule(
    name: ModuleType.domain(.novel).name,
    targets: [.sources, .testing, .tests],
    internalDependencies: [.module(.domain(.base))],
    // 키워드를 붙여 불러오는 UseCase 테스트가 BaseDomain의 MockLoadTotalKeywordsUseCase를 쓴다.
    testDependencies: [.module(.domain(.base), type: .testing)]
)
