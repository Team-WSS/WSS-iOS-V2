//
//  LinkNovelGenreStyle.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 5/5/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import SwiftUI
import DesignSystem

extension LinkNovelGenreType {
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
        case .bl:               WSSColor.blLink.swiftUIColor
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
        case .bl:               WSSColor.blBlock.swiftUIColor
        }
    }
}
