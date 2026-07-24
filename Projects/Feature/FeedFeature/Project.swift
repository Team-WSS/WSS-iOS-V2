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
        .module(.domain(.comment)),
        .module(.domain(.social)),
        .module(.domain(.profile)),
        .module(.ui(.designSystem)),
        .module(.ui(.wssComponent)),
        .module(.core(.logger))
    ],
    demoDependencies: [
        .module(.core(.networking)),
        .module(.data(.base)),
        .module(.data(.feed)),
        .module(.data(.novel)),
        .module(.data(.profile)),
        .module(.data(.social))
    ]
)
