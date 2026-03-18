//
//  ProfileDraft.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public struct ProfileDraft {
    public private(set) var characterID: Int
    public private(set) var nickname: NicknameDraft
    public private(set) var introduction: String
    public private(set) var genrePreferences: [GenrePreference]
    
    private let initialCharacterID: Int
    private let initialIntroduction: String
    private let initialGenrePreferences: [GenrePreference]
    
    // MARK: - Init
    
    public init(
        characterID: Int,
        nickname: String,
        introduction: String,
        genrePreferences: [GenrePreference]
    ) {
        self.characterID = characterID
        self.nickname = NicknameDraft(nickname)
        self.introduction = introduction
        self.genrePreferences = genrePreferences
        
        self.initialCharacterID = characterID
        self.initialIntroduction = introduction
        self.initialGenrePreferences = genrePreferences
    }
    
    // MARK: - Change Detection

    public var isCharacterChanged: Bool { characterID != initialCharacterID }
    public var isNicknameChanged: Bool { nickname.validationState == .available }
    public var isIntroductionChanged: Bool { introduction != initialIntroduction }
    public var isGenrePreferencesChanged: Bool { genrePreferences != initialGenrePreferences }

    // MARK: - Policy

    public var isSubmittable: Bool {
        // 닉네임이 변경 중인데 유효하지 않은 경우 제출 불가
        switch nickname.validationState {
        case .needDuplicatedCheck:
            return false
        case .notAvailable(let reason) where reason != .notChanged:
            return false
        default:
            break
        }

        return isNicknameChanged || isIntroductionChanged || isCharacterChanged || isGenrePreferencesChanged
    }
    
    // MARK: - Mutating
    
    // - character
    
    public mutating func setCharacter(_ newCharacterID: Int) {
        self.characterID = newCharacterID
    }
    
    // - nickname
    
    public mutating func updateNickname(_ newNickname: String) {
        nickname.setText(newNickname)
    }
    
    public mutating func applyNicknameDuplicationCheck(
        _ state: NicknameDraft.DuplicationCheckState,
        checkedText: String
    ) {
        nickname.applyDuplicationCheckResult(state, checkedText: checkedText)
    }
    
    // - introduction
    
    private static let maxIntroductionLength: Int = 50
    private static let maxLineCount: Int = 3
    
    public mutating func updateIntroduction(_ newValue: String) {
        var lines = newValue.components(separatedBy: "\n")
        
        if lines.count > Self.maxLineCount {
            lines = Array(lines.prefix(Self.maxLineCount))
        }
        
        var text = lines.joined(separator: "\n")
        text = String(text.prefix(Self.maxIntroductionLength))
        
        self.introduction = text
    }
    
    // - genre preferences
    
    public mutating func addGenrePreference(_ genre: GenrePreference) {
        genrePreferences.append(genre)
    }
    
    public mutating func removeGenrePreference(_ genre: GenrePreference) {
        genrePreferences.removeAll { $0 == genre }
    }
}
