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
    static func relativeToFeature(_ path: String) -> Self {
        return .relativeToRoot("Projects/Feature/\(path)")
    }
    static func relativeToDomain(_ path: String) -> Self {
        return .relativeToRoot("Projects/Domain/\(path)")
    }
    static func relativeToData(_ path: String) -> Self {
        return .relativeToRoot("Projects/Data/\(path)")
    }
    static func relativeToCore(_ path: String) -> Self {
        return .relativeToRoot("Projects/Core/\(path)")
    }
    static func relativeToUI(_ path: String) -> Self {
        return .relativeToRoot("Projects/UI/\(path)")
    }
    static var app: Self {
        return .relativeToRoot("Projects/App")
    }
}
