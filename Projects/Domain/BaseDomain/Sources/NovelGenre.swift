//
//  NovelGenre.swift
//  BaseDomain
//
//  Created by Seoyeon Choi on 1/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public enum NovelGenre: CaseIterable {
    case lightNovel
    case wuxia
    case fantasy
    case romance
    case BL
    case romanceFantasy
    case modernFantasy
    case drama
    case mystery
}

extension NovelGenre {
    public static let filterGenre: [NovelGenre] = [.romance, .romanceFantasy, .fantasy, .modernFantasy, .wuxia, .mystery, .drama, .lightNovel, .BL]
}
