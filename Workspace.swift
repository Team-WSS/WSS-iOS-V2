//
//  Workspace.swift
//  Config
//
//  Created by YunhakLee on 10/1/25.
//

import Foundation
import ProjectDescription

let workspace = Workspace(
    name: "WSS-iOS-V2",
    projects: [
        "Projects/App",
        "Projects/Core/Keychain",
        "Projects/Core/Network"
    ]
)
