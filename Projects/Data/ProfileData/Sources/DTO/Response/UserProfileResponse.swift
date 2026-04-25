//
//  UserProfileResponse.swift
//  ProfileData
//
//  Created by WonsunLee on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

struct UserProfileResponse: Decodable {
    let nickname: String
    let intro: String
    let avatarImage: String
    let isProfilePblic: Bool
    let genrePreferences: [String]
}
