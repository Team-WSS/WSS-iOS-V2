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
    public let debugBundleId: String
    public let releaseBundleId: String
    public let appleDeveloperTeamID: String
    public let deploymentTarget: DeploymentTargets
    public let destination: ProjectDescription.Destinations
    public let baseSetting: SettingsDictionary
}

public let env = ProjectEnvironment(
    appName: "Websoso",
    targetName: "WSS-iOS",
    targetTestName: "WSS-iOSTests",
    // App 자체 bundle id는 debugBundleId/releaseBundleId로 별도 분리돼 있어(아래) 여기 값은 App 외
    // 프레임워크 모듈들의 bundle id 접두사로만 쓰인다(Project+Templates.swift) — App Store 심사·
    // Apple/Kakao 로그인 계약과는 무관. V1(운영 앱)의 실제 조직명 표기와 맞추려고 접미사를 뗐다(#231).
    organizationName: "kr.websoso",
    debugBundleId: "kr.websoso.debug2",
    releaseBundleId: "kr.websoso",
    appleDeveloperTeamID: "9SVDHQS4M3",
    deploymentTarget: .iOS("17.0"),
    destination: .iOS,
    baseSetting: [:]
)
