//
//  Project.swift
//  AppManifests
//
//  Created by Seoyeon Choi on 7/8/26.
//

import Foundation

import ProjectDescription
import ProjectDescriptionHelpers
import DependencyPlugin

let project = Project.createFeatureModule(
    name: ModuleType.feature(.userPage).name,
    targets: [.sources, .demo],
    internalDependencies: [
        .module(.domain(.base)),
        .module(.domain(.profile)),
        .module(.domain(.novel)),
        .module(.domain(.feed)),
        .module(.domain(.social)),
        .module(.domain(.collection)),
        .module(.ui(.designSystem)),
        .module(.ui(.wssComponent)),
        .module(.core(.logger))
    ],
    demoDependencies: [
        .module(.core(.networking)),
        .module(.core(.logger)),
        .module(.data(.base)),
        .module(.data(.profile)),
        .module(.data(.novel)),
        .module(.data(.feed)),
        .module(.data(.social)),
        .module(.data(.collection))
    ]
)
