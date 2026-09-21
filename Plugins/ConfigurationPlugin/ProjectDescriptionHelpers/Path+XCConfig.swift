//
//  Path+XCConfig.swift
//  ConfigurationPlugin
//
//  Created by Seoyeon Choi on 11/10/25.
//

import ProjectDescription

public extension ProjectDescription.Path {
    static func relativeToXCConfig(type: ProjectConfiguration, name: String) -> Self {
        return .relativeToRoot("Config/Config_\(type.rawValue).xcconfig")
    }
    
    static var shared: String {
        return "Config/Config_Shared.xcconfig"
    }
}
