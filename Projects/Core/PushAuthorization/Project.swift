//
//  Project.swift
//  Manifests
//
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createCoreModule(
    name: ModuleType.core(.pushAuthorization).name,
    targets: [.sources, .demo]
)
