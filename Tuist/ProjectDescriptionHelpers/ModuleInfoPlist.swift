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
    
    public var dictionary: [String: Plist.Value] {
        switch self {
        case .feature:
            return [
                "CFBundleIdentifier": "$(PRODUCT_BUNDLE_IDENTIFIER)",
                "CFBundleName": "$(TARGET_NAME)"
            ]
        case .domain:
            return [
                "CFBundleIdentifier": "$(PRODUCT_BUNDLE_IDENTIFIER)",
                "CFBundleName": "$(TARGET_NAME)"
            ]
        case .data:
            return [
                "CFBundleIdentifier": "$(PRODUCT_BUNDLE_IDENTIFIER)",
                "CFBundleName": "$(TARGET_NAME)",
                "AMPLITUDE_API_KEY": "$(AMPLITUDE_API_KEY)",
                "BASE_URL": "$(BASE_URL)",
                "TEST_API_KEY": "$(TEST_API_KEY)"
            ]
        case .core:
            return [
                "CFBundleIdentifier": "$(PRODUCT_BUNDLE_IDENTIFIER)",
                "CFBundleName": "$(TARGET_NAME)"
            ]
        case .ui:
            return [
                "CFBundleIdentifier": "$(PRODUCT_BUNDLE_IDENTIFIER)",
                "CFBundleName": "$(TARGET_NAME)"
            ]
        }
    }
    
    public var infoPlist: InfoPlist {
        .extendingDefault(with: self.dictionary)
    }
}
