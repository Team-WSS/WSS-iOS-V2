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
    name: ModuleType.Data.notification.name,
    targets: [.sources, .demo, .tests],
    internalDependencies: [
        .Core.Networking,
        .Core.Logger,
        .Domain.makeDependency(for: .base, type: .sources),
        .Domain.makeDependency(for: .notification, type: .sources)
    ]
)
