//
//  ProjectDescriptionPath+.swift
//  Plugins
//
//  Created by Seoyeon Choi on 11/10/25.
//

import ProjectDescription

public extension ProjectDescription.Path {
    static func relativeToSections(_ path: String) -> Self {
        return .relativeToRoot("Projects/\(path)")
    }
    static func relativeToFeature(_ path: ModuleType.Feature) -> Self {
        return .relativeToRoot("Projects/Feature/\(path)")
    }
    static func relativeToDomain(_ path: ModuleType.Domain) -> Self {
        return .relativeToRoot("Projects/Domain/\(path)")
    }
    static func relativeToData(_ path: ModuleType.Data) -> Self {
        return .relativeToRoot("Projects/Data/\(path)")
    }
    static func relativeToCore(_ path: ModuleType.Core) -> Self {
        return .relativeToRoot("Projects/Core/\(path)")
    }
    static func relativeToUI(_ path: ModuleType.UI) -> Self {
        return .relativeToRoot("Projects/UI/\(path)")
    }
    static var app: Self {
        return .relativeToRoot("Projects/App")
    }
}
