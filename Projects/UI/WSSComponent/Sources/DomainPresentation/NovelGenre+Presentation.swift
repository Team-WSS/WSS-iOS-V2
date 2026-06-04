//
//  NovelGenre+Presentation.swift
//  WSSComponent
//
//  Created by YunhakLee on 5/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain
import SwiftUI
import DesignSystem

public extension NovelGenre {
    var displayName: String {
        switch self {
        case .fantasy:          "판타지"
        case .modernFantasy:    "현판"
        case .wuxia:            "무협"
        case .drama:            "드라마"
        case .mystery:          "미스터리"
        case .lightNovel:       "라노벨"
        case .romance:          "로맨스"
        case .romanceFantasy:   "로판"
        case .BL:               "BL"
        }
    }
    
    var iconImage: Image {
        switch self {
        case .fantasy:          WSSImage.icGenreF.swiftUIImage
        case .modernFantasy:    WSSImage.icGenreHF.swiftUIImage
        case .wuxia:            WSSImage.icGenreMH.swiftUIImage
        case .drama:            WSSImage.icGenreD.swiftUIImage
        case .mystery:          WSSImage.icGenreMT.swiftUIImage
        case .lightNovel:       WSSImage.icGenreLN.swiftUIImage
        case .romance:          WSSImage.icGenreR.swiftUIImage
        case .romanceFantasy:   WSSImage.icGenreRF.swiftUIImage
        case .BL:               WSSImage.icGenreBL.swiftUIImage
        }
    }
    
    var markImage: Image {
        switch self {
        case .fantasy:          WSSImage.icGenremarkF.swiftUIImage
        case .modernFantasy:    WSSImage.icGenremarkHF.swiftUIImage
        case .wuxia:            WSSImage.icGenremarkMH.swiftUIImage
        case .drama:            WSSImage.icGenremarkD.swiftUIImage
        case .mystery:          WSSImage.icGenremarkMT.swiftUIImage
        case .lightNovel:       WSSImage.icGenremarkLN.swiftUIImage
        case .romance:          WSSImage.icGenremarkR.swiftUIImage
        case .romanceFantasy:   WSSImage.icGenremarkRF.swiftUIImage
        case .BL:               WSSImage.icGenremarkBL.swiftUIImage
        }
    }
    
    var linkColor: Color {
        switch self {
        case .romance:          WSSColor.romanceLink.swiftUIColor
        case .romanceFantasy:   WSSColor.rofanLink.swiftUIColor
        case .fantasy:          WSSColor.fantasyLink.swiftUIColor
        case .modernFantasy:    WSSColor.modernLink.swiftUIColor
        case .wuxia:            WSSColor.wuxiaLink.swiftUIColor
        case .mystery:          WSSColor.mysteryLink.swiftUIColor
        case .drama:            WSSColor.dramaLink.swiftUIColor
        case .lightNovel:       WSSColor.lightLink.swiftUIColor
        case .BL:               WSSColor.blLink.swiftUIColor
        }
    }
    
    var blockColor: Color {
        switch self {
        case .romance:          WSSColor.romanceBlock.swiftUIColor
        case .romanceFantasy:   WSSColor.rofanBlock.swiftUIColor
        case .fantasy:          WSSColor.fantasyBlock.swiftUIColor
        case .modernFantasy:    WSSColor.modernBlock.swiftUIColor
        case .wuxia:            WSSColor.wuxiaBlock.swiftUIColor
        case .mystery:          WSSColor.mysteryBlock.swiftUIColor
        case .drama:            WSSColor.dramaBlock.swiftUIColor
        case .lightNovel:       WSSColor.lightBlock.swiftUIColor
        case .BL:               WSSColor.blBlock.swiftUIColor
        }
    }
}
