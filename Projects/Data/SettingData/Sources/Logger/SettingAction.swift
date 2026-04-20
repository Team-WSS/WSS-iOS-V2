//
//  SettingAction.swift
//  SettingData
//
//  Created by YunhakLee on 4/20/26.
//

enum SettingAction {
    case loadAppUpdatePolicy
    case loadTermsAgreementDraft
    case saveTermsAgreementDraft

    var text: String {
        switch self {
        case .loadAppUpdatePolicy:
            return "loadAppUpdatePolicy"
        case .loadTermsAgreementDraft:
            return "loadTermsAgreementDraft"
        case .saveTermsAgreementDraft:
            return "saveTermsAgreementDraft"
        }
    }
}
