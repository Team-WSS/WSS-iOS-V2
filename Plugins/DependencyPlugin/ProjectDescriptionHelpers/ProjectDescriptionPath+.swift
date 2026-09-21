//
//  ProjectDescriptionPath+.swift
//  Plugins
//
//  Created by Seoyeon Choi on 11/10/25.
//

import ProjectDescription

public extension ProjectDescription.Path {
    static func relativeToModule(_ module: ModuleType) -> Self {
        return .relativeToRoot("Projects/\(module.directoryName)/\(module.name)")
    }

    static var app: Self {
        return .relativeToRoot("Projects/App")
    }
}
