//
//  ConfigurationName+.swift
//  ConfigurationPlugin
//
//  Created by Seoyeon Choi on 11/10/25.
//

import ProjectDescription

public extension ConfigurationName {
    static var dev: ConfigurationName { ProjectConfiguration.dev.configurationName }
    static var prod: ConfigurationName { ProjectConfiguration.prod.configurationName }
}
