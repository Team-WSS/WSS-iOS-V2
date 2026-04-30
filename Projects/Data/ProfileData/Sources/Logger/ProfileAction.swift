//
//  ProfileAction.swift
//  ProfileData
//
//  Created by Lee Wonsun on 4/30/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

enum ProfileAction: String {
    case syncUserBasicInfo
    case validateNickname
    case registerProfile
    case loadAccountInfoDraft
    case saveAccountInfo
    case loadProfileVisibility
    case updateProfileVisibility
    case fetchUserProfile
    case fetchGenrePreferences
    case fetchNovelPreferences
    case fetchProfileCharacters
    case loadInitialProfile
    case updateProfile
    
    var name: String { return self.rawValue }
}
