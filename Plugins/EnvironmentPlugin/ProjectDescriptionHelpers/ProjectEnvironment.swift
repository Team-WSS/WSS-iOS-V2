//
//  ProjectEnvironment.swift
//  ConfigurationPlugin
//
//  Created by Seoyeon Choi on 11/10/25.
//

import ProjectDescription

public struct ProjectEnvironment {
    public let appName: String
    public let targetName: String
    public let targetTestName: String
    public let organizationName: String
    public let deploymentTarget: DeploymentTargets
    public let destination: ProjectDescription.Destinations
    public let baseSetting: SettingsDictionary
}

public let env = ProjectEnvironment(
    appName: "Websoso",
    targetName: "WSS-iOS",
    targetTestName: "WSS-iOSTests",
    organizationName: "kr.websoso.app",
    deploymentTarget: .iOS("17.0"),
    destination: .iOS,
    baseSetting: [:]
)
