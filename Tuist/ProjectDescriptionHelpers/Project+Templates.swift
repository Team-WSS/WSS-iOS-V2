import ProjectDescription

// MARK: - Common Framework Template

extension Project {
    public static func framework(
        name: String,
        bundleIdPrefix: String = "io.tuist",
        dependencies: [TargetDependency] = [],
        hasTests: Bool = false,
        hasDemo: Bool = false,
        infoPlist: InfoPlist = .default
    ) -> Project {
        let lowerName = name.lowercased()
        let bundleId = "\(bundleIdPrefix).\(lowerName)"

        var targets: [Target] = [
            .target(
                name: name,
                destinations: .iOS,
                product: .framework,
                bundleId: bundleId,
                deploymentTargets: .iOS("16.0"),
                infoPlist: infoPlist,
                sources: ["Sources/**"],
                resources: [],
                dependencies: dependencies
            )
        ]

        if hasTests {
            targets.append(
                .target(
                    name: "\(name)Tests",
                    destinations: .iOS,
                    product: .unitTests,
                    bundleId: "\(bundleIdPrefix).\(lowerName).tests",
                    deploymentTargets: .iOS("16.0"),
                    infoPlist: .default,
                    sources: ["Tests/**"],
                    resources: [],
                    dependencies: [.target(name: name)]
                )
            )
        }

        if hasDemo {
            targets.append(
                .target(
                    name: "\(name)Demo",
                    destinations: .iOS,
                    product: .app,
                    bundleId: "\(bundleIdPrefix).\(lowerName).demo",
                    deploymentTargets: .iOS("16.0"),
                    infoPlist: .extendingDefault(with: [
                        "UILaunchScreen": [:],
                        "CFBundleDisplayName": "\(name) Demo"
                    ]),
                    sources: ["Demo/**"],
                    resources: ["Demo/Resources/**"],
                    dependencies: [.target(name: name)] + dependencies
                )
            )
        }

        return Project(
            name: name,
            settings: .settings(configurations: [
                .debug(name: .debug),
                .release(name: .release)
            ]),
            targets: targets
        )
    }
}
