//
//  WithdrawalDraft.swift
//  AuthDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


public struct WithdrawalReasonDraft: Equatable {
    public private(set) var option: WithdrawalReasonOption = WithdrawalReasonOption.allCases.first ?? .notFrequentlyUsed
    public private(set) var customReasonText: String = ""
    public private(set) var policyAgreed: Bool = false
    
    // MARK: - Policy

    public static let maxCustomReasonLength = 80
    
    public var isSubmittable: Bool {
        let validOption = !option.requiresText || !customReasonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        return validOption && policyAgreed
    }
    
    // MARK: - Init

    public init() {}

    // MARK: - Mutating
    
    public mutating func setOption(_ option: WithdrawalReasonOption) {
        if !option.requiresText { customReasonText = "" }
        self.option = option
    }

    public mutating func setCustomReasonText(_ text: String) {
        guard option.requiresText else { return }
        self.customReasonText = String(text.prefix(Self.maxOtherLength))
    }
    
    public mutating func setPolicyAgreed(_ isAgreed: Bool) {
        self.policyAgreed = isAgreed
    }
}
