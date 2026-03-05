//
//  Profile.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import BaseDomain

public struct Profile {
    public let nickname: String
    public let introduction: String
    public let characterImage: URL?
    public let isPublic: Bool
    public let genrePreferences: [NovelGenre]
}
