//
//  ModuleInfoPlist.swift
//  Manifests
//
//  Created by Seoyeon Choi on 11/11/25.
//

import ProjectDescription

public enum ModuleInfoPlist {
    
    case feature
    case featureDemo
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
            return commonEntries
        case .featureDemo:
            var entries = commonEntries
            entries["BASE_URL"] = "$(BASE_URL)"
            entries["TEST_API_KEY"] = "$(TEST_API_KEY)"
            entries["BUCKET_URL"] = "$(BUCKET_URL)"
            // 카카오 로그인 리다이렉트 수신용(OnboardingFeatureDemo). 다른 Demo는 미사용이라도 무해.
            entries["KAKAO_APP_KEY"] = "$(KAKAO_APP_KEY)"
            entries["CFBundleURLTypes"] = .array([
                .dictionary([
                    "CFBundleURLSchemes": .array([.string("kakao$(KAKAO_APP_KEY)")])
                ])
            ])
            return entries
        case .domain:
            return commonEntries
        case .data:
            var entries = commonEntries
            entries["AMPLITUDE_API_KEY"] = "$(AMPLITUDE_API_KEY)"
            entries["BASE_URL"] = "$(BASE_URL)"
            entries["TEST_API_KEY"] = "$(TEST_API_KEY)"
            entries["BUCKET_URL"] = "$(BUCKET_URL)"
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
