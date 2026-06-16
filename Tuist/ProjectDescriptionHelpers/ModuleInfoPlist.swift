//
//  ModuleInfoPlist.swift
//  Manifests
//
//  Created by Seoyeon Choi on 11/11/25.
//

import ProjectDescription

public enum ModuleInfoPlist {
    
    case feature
    case domain
    case data
    case core
    case ui
    
    private var commonEntries: [String: Plist.Value] {
        [
            "CFBundleIdentifier": "$(PRODUCT_BUNDLE_IDENTIFIER)",
            "CFBundleName": "$(TARGET_NAME)",
            "UILaunchScreen": .dictionary([:]),
            "UISupportedInterfaceOrientations~ipad": .array([
                .string("UIInterfaceOrientationPortrait")
            ])
        ]
    }
    
    public var dictionary: [String: Plist.Value] {
        switch self {
        case .feature:
            var entries = commonEntries
            // Feature Demo 타깃에서 실제 API 조립을 검증할 때 NetworkingConfig가
            // Info.plist에서 읽어가는 키들. Sources 자체는 Data import를 안 하므로
            // 정상 흐름에서는 의미가 없고, demo 타깃에서만 의미를 갖는다.
            entries["BASE_URL"] = "$(BASE_URL)"
            entries["TEST_API_KEY"] = "$(TEST_API_KEY)"
            return entries
        case .domain:
            return commonEntries
        case .data:
            var entries = commonEntries
            entries["AMPLITUDE_API_KEY"] = "$(AMPLITUDE_API_KEY)"
            entries["BASE_URL"] = "$(BASE_URL)"
            entries["TEST_API_KEY"] = "$(TEST_API_KEY)"
            return entries
        case .core:
            return commonEntries
        case .ui:
            return commonEntries
        }
    }
    
    public var infoPlist: InfoPlist {
        .extendingDefault(with: self.dictionary)
    }
}
