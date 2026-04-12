//
//  Project.swift
//  AppManifests
//
//  Created by Seoyeon Choi on 3/27/26.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createDataModule(
    name: ModuleType.Data.novel.name,
    targets: [.sources, .demo, .tests],
    internalDependencies: [
        .Core.Networking,
        .Domain.NovelDomain,
        .Domain.BaseDomain
    ]
)
