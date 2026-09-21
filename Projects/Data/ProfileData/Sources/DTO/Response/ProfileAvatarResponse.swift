//
//  ProfileCharacterResponse.swift
//  ProfileData
//
//  Created by WonsunLee on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

struct ProfileAvatarResponse: Decodable {
    let avatarProfiles: [ProfileAvatar]
}

struct ProfileAvatar: Decodable {
    let avatarProfileId: Int
    let avatarProfileName: String
    let avatarProfileLine: String
    let avatarProfileImage: String
    let avatarCharacterImage: String
    let isRepresentative: Bool
}
