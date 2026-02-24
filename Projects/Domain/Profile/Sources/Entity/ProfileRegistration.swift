//
//  ProfileRegistration.swift
//  ProfileDomain
//
//  Created by YunhakLee on 2/24/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain

public struct ProfileRegistration: Equatable {
    public let nickname: String
    public let gender: Gender
    public let birthYear: BirthYear
    public let genrePreferences: [NovelGenre]
}
