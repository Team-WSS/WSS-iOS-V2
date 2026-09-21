//
//  ProfileEditInfoResponse.swift
//  ProfileData
//
//  Created by WonsunLee on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

struct ProfileEditInfoResponse: Decodable {
    let introduction: String
    let genrePreferences: [GenrePreferences]
}
