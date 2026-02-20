//
//  TermsAgreementDraft.swift
//  SettingDomain
//
//  Created by YunhakLee on 2/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


public struct TermsAgreementDraft: Equatable {
    
    public private(set) var agreements: [TermsType: Bool]
    
    // MARK: - Policy
    
    public var isSubmittable: Bool {
        TermsType.allCases
            .filter { $0.isRequired }
            .allSatisfy { agreements[$0] == true }
    }

    // MARK: - Init
    
    public init(initial: [TermsType: Bool] = [:]) {
        var dict: [TermsType: Bool] = [:]
        for t in TermsType.allCases {
            dict[t] = initial[t] ?? false
        }
        self.agreements = dict
    }
    
    // MARK: - Draft Editing
    
    public func isAgreed(_ type: TermsType) -> Bool {
        agreements[type] ?? false
    }

    public mutating func setAgreed(_ isAgreed: Bool, for type: TermsType) {
        agreements[type] = isAgreed
    }

    public mutating func agreeToAll() {
        for t in TermsType.allCases { agreements[t] = true }
    }
}
