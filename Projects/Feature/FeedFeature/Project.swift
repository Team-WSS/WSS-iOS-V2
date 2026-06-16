//
//  Project.swift
//  AppManifests
//
//  Created by Seoyeon Choi on 6/4/26.
//

import Foundation

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createFeatureModule(
    name: ModuleType.feature(.feed).name,
    targets: [.sources, .demo],
    internalDependencies: [
        .module(.domain(.base)),
        .module(.domain(.feed)),
        .module(.domain(.novel)),
        .module(.domain(.social)),
        .module(.domain(.comment)),
        .module(.ui(.designSystem)),
        .module(.ui(.wssComponent))
    ],
    // Demo 전용 의존: 실제 API 연결 검증을 위해 Data/Networking 조립을 demo 타깃에서만 허용한다.
    // Feature Sources 자체는 Data를 import 하지 않는다 (CLAUDE.md 룰 유지).
    demoDependencies: [
        .module(.data(.base)),
        .module(.data(.feed)),
        .module(.data(.comment)),
        .module(.core(.networking)),
        .module(.core(.logger))
    ]
)
