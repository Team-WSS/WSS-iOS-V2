//
//  GenrePreference.swift
//  ProfileDomain
//
//  Created by Seoyeon Choi on 2/25/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public struct GenrePreference: Equatable, Sendable {
    public let genre: NovelGenre
    public let count: Int

    public init(
        genre: NovelGenre,
        count: Int
    ) {
        self.genre = genre
        self.count = count
    }
}
