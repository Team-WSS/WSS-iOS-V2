//
//  NovelGenre.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

public enum NovelGenre: String {
    case lightNovel
    case wuxia
    case fantasy
    case romance
    case BL
    case romanceFantasy
    case modernFantasy
    case drama
    case mystery
    
    var title: String {
        switch self {
        case .lightNovel:       return "라노벨"
        case .wuxia:            return "무협"
        case .fantasy:          return "판타지"
        case .romance:          return "로맨스"
        case .BL:               return "BL"
        case .romanceFantasy:   return "로판"
        case .modernFantasy:    return "현판"
        case .drama:            return "드라마"
        case .mystery:          return "미스터리"
        }
    }
}

extension NovelGenre {
    public static let filterGenre: [NovelGenre] = [.romance, .romanceFantasy, .fantasy, .modernFantasy, .wuxia, .mystery, .drama, .lightNovel, .BL]
}
