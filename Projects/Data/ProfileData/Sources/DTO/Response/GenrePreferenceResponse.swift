//
//  GenrePreferenceResponse.swift
//  ProfileData
//
//  Created by WonsunLee on 4/23/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

struct GenrePreferenceResponse: Decodable {
    let genrePreferences: [GenrePreferences]
}

struct GenrePreferences: Decodable {
    let genreName: String
    let genreImage: String
    let genreCount: Int
}
