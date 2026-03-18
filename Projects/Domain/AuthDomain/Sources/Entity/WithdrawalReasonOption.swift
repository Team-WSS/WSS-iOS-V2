//
//  WithdrawalReasonOption.swift
//  AuthDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

public enum WithdrawalReasonOption: CaseIterable, Equatable {
    case notFrequentlyUsed
    case inconvenientAndBuggy
    case wantToDeleteContent
    case noDesiredContent
    case custom

    public var requiresText: Bool { self == .custom }
}
