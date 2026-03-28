//
//  Project.swift
//  AppManifests
//
//  Created by YunhakLee on 11/25/25.
//

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createDataModule(
    name: ModuleType.Data.novelReview.name,
    targets: [.sources, .tests, .testing],
    internalDependencies: [
        .Core.Networking,
        .Core.Logger,
        .Domain.makeDependency(for: .novelReview, type: .sources),
        .Domain.makeDependency(for: .base, type: .sources)
    ]
)
