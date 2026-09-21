//
//  KeywordCategory+Presentation.swift
//  WSSComponent
//
//  Created by Seoyeon Choi on 7/24/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain
import SwiftUI
import DesignSystem

public extension KeywordCategory {
    var displayName: String {
        switch self {
        case .worldview:    "세계관"
        case .material:     "소재"
        case .character:    "캐릭터"
        case .relationship: "관계"
        case .vibe:         "분위기"
        }
    }

    var iconImage: Image {
        switch self {
        case .worldview:    WSSImage.icCategoryWorld.swiftUIImage
        case .material:     WSSImage.icCategoryMaterial.swiftUIImage
        case .character:    WSSImage.icCategoryCharacter.swiftUIImage
        case .relationship: WSSImage.icCategoryRelationship.swiftUIImage
        case .vibe:         WSSImage.icCategoryVibe.swiftUIImage
        }
    }
}
