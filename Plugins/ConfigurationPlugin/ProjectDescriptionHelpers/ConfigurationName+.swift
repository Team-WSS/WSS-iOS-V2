//
//  ConfigurationName+.swift
//  ConfigurationPlugin
//
//  Created by Seoyeon Choi on 11/10/25.
//

import ProjectDescription

public extension ConfigurationName {
    static var dev: ConfigurationName { configuration(ProjectConfiguration.dev.rawValue) }
    static var prod: ConfigurationName { configuration(ProjectConfiguration.prod.rawValue) }
}
