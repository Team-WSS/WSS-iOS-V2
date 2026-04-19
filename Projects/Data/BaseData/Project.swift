//
//  Project.swift
//  Manifests
//
//  Created by Wonsun Lee on 4/13/26.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createDataModule(
    name: ModuleType.Data.base.name,
    targets: [.sources],
    internalDependencies: [
        .Core.Networking,
        .Core.Logger,
        .Domain.BaseDomain
    ]
)
