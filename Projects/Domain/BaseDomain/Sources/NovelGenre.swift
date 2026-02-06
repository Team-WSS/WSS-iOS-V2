//
//  NovelGenre.swift
//  BaseDomain
//
//  Created by Seoyeon Choi on 1/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

<<<<<<< HEAD
public enum NovelGenre {
=======
public enum NovelGenre: String {
>>>>>>> 111d6aa ([Chore] #21 - BaseDomain 추가 및 FeedDomain에 의존성 주입)
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
