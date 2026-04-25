//
//  UpdateProfileRequest.swift
//  ProfileData
//
//  Created by WonsunLee on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Networking

struct UpdateProfileRequest: RequestBodyConvertible {
    let avatarId: Int
    let nickname: String
    let intro: String
    let genrePreferences: [String]
}
