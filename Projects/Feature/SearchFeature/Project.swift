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
        .module(.domain(.novel)),
        .module(.ui(.designSystem)),
        .module(.ui(.wssComponent)),
        .module(.core(.logger))
    ],
    demoDependencies: [
        .module(.data(.recommendation)),
        .module(.data(.search)),
        .module(.data(.novel)),
        .module(.data(.base)),
        .module(.core(.networking))
    ]
)
