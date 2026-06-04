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
    targets: [.sources, .demo],
    internalDependencies: [
        .module(.domain(.base)),
        .module(.domain(.novelReview)),
        .module(.ui(.designSystem)),
        .module(.ui(.wssComponent))
    ]
)
