//
//  Project.swift
//  AppManifests
//
//  Created by Seoyeon Choi on 4/9/26.
//

import Foundation

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createDataModule(
    name: ModuleType.Data.keyword.name,
    targets: [.sources, .testing, .tests],
    internalDependencies: [
        .Core.Networking,
        .Core.Logger,
        .Domain.makeDependency(for: .base, type: .sources),
        .Domain.makeDependency(for: .keyword, type: .sources)
    ]
)
