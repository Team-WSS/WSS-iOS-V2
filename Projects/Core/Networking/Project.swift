//
//  Package.swift
//  AppManifests
//
//  Created by YunhakLee on 10/21/25.
//

import Foundation
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.framework(
    name: "Networking",
    dependencies: [
        .project(target: "Logger", path: "../Logger")
    ],
    hasTests: true,
    hasDemo: true
)
