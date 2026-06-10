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
        .module(.ui(.designSystem)),
        .module(.ui(.wssComponent))
    ]
)
