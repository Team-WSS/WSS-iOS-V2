//
//  WithdrawalDraft.swift
//  AuthDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


public struct WithdrawalReasonDraft: Equatable {
    public private(set) var option: WithdrawalReasonOption
    public private(set) var customReasonText: String
    
    // MARK: - Policy

    public static let maxOtherLength = 80
    
    public var isSubmittable: Bool {
        guard !option.requiresText else {
            return !customReasonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return true
    }
    
    // MARK: - Init

    public init(
        option: WithdrawalReasonOption = .noLongerInterested,
        customReasonText: String = ""
    ) {
        self.option = option
        self.customReasonText = customReasonText
    }

    // MARK: - Mutating
    
    public mutating func setOption(_ option: WithdrawalReasonOption) {
        if !option.requiresText { customReasonText = "" }
        self.option = option
    }

    public mutating func setOtherText(_ text: String) {
        self.customReasonText = String(text.prefix(Self.maxOtherLength))
    }
}
