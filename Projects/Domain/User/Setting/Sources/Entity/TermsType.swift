//
//  TermsType.swift
//  SettingDomain
//
//  Created by YunhakLee on 2/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


public enum TermsType: CaseIterable, Hashable {
    case serviceAgreement
    case privacyPolicy
    case marketingConsent

    public var isRequired: Bool {
        switch self {
        case .serviceAgreement, .privacyPolicy: return true
        case .marketingConsent: return false
        }
    }
}
