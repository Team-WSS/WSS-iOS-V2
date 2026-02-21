//
//  WithdrawalReasonOption.swift
//  AuthDomain
//
//  Created by YunhakLee on 2/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//


public enum WithdrawalReasonOption: CaseIterable, Equatable {
    case noLongerInterested
    case tooManyNotifications
    case foundBetterService
    case privacyConcern
    case inconvenientToUse
    case customReason

    public var requiresText: Bool { self == .customReason }
}
