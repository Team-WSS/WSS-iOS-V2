//
//  NicknameDraft.swift
//  ProfileDomain
//
//  Created by YunhakLee on 2/24/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct NicknameDraft {
    
    public private(set) var text: String = ""
    
    // MARK: INIT
    
    public init(_ initialName: String) {
        lastNickname = initialName
        text = initialName
    }

    // MARK: Policy
    
    private let lastNickname: String
    private var duplicationCheckState: DuplicationCheckState = .notYet
    private static let maxLength: Int = 10
    private static let nicknamePattern = "^[a-zA-Z0-9가-힣]{2,10}$"
 
    
    public var validationState: ValidationState {
        if text.isEmpty {
            return .notStarted
        }
        
        if containsWhitespace {
            return .notAvailable(reason: .whiteSpaceIncluded)
        }
        
        if !isChanged {
            return .notAvailable(reason: .notChanged)
        }
        
        if self.isValidPattern {
            switch duplicationCheckState {
            case .notYet: return .needDuplicatedCheck
            case .duplicated: return .notAvailable(reason: .duplicated)
            case .notDuplicated: return .available
            }
        } else {
            return .notAvailable(reason: .invalidCharacterOrLimitExceeded)
        }
        
    }
    
    private var isValidPattern: Bool {
        text.range(of: Self.nicknamePattern, options: .regularExpression) != nil
    }
    
    private var containsWhitespace: Bool {
        text.rangeOfCharacter(from: .whitespacesAndNewlines) != nil
    }
    
    private var isChanged: Bool {
        text != lastNickname
    }
    
    public enum ValidationState: Equatable {
        case notStarted
        case notAvailable(reason: NotAvailableReason)
        case needDuplicatedCheck
        case available
    }

    public enum NotAvailableReason: Equatable {
        case whiteSpaceIncluded
        case invalidCharacterOrLimitExceeded
        case duplicated
        case notChanged
    }
    
    public enum DuplicationCheckState: Equatable {
        case notYet
        case duplicated
        case notDuplicated
    }
    
    // MARK: Mutating
    
    public mutating func setText(
        _ newValue: String
    ) {
        let clippedText = String(newValue.prefix(Self.maxLength))
        if clippedText != text { duplicationCheckState = .notYet }
        self.text = clippedText
    }
    
    public mutating func applyDuplicationCheckResult(
        _ status: DuplicationCheckState,
        checkedText: String
    ) {
        guard checkedText == text else { return }
        duplicationCheckState = status
    }
}
