//
//  Dependency+Target.swift
//  Plugins
//
//  Created by Seoyeon Choi on 11/10/25.
//

import ProjectDescription

public extension TargetDependency {
    static func module(_ module: ModuleType, type: TargetType = .sources) -> TargetDependency {
        .project(
            target: module.targetName(type: type),
            path: .relativeToModule(module)
        )
    }

    static var lottie: TargetDependency {
        .xcframework(path: .relativeToRoot("Tuist/.build/artifacts/lottie-spm/Lottie/Lottie.xcframework"))
    }
}
