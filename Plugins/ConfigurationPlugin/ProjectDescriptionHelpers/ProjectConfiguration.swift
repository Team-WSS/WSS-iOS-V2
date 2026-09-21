//
//  ProjectConfiguration.swift
//  ConfigurationPlugin
//
//  Created by Seoyeon Choi on 11/10/25.
//

import Foundation
import ProjectDescription

public enum ProjectConfiguration: String {
    case dev = "Debug"
    case prod = "Release"

    public var configurationName: ConfigurationName {
        ConfigurationName.configuration(self.rawValue)
    }
}
