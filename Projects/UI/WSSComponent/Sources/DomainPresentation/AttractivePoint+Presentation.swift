//
//  AttractivePoint+Presentation.swift
//  WSSComponent
//
//  Created by YunhakLee on 5/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain
import SwiftUI
import DesignSystem

extension AttractivePoint {
    var displayName: String {
        switch self {
        case .worldview:    "세계관"
        case .material:     "소재"
        case .writingSkill: "필력"
        case .character:    "캐릭터"
        case .relationship: "관계"
        case .vibe:         "분위기"
        }
    }
    
    var iconImage: Image {
        switch self {
        case .worldview:    WSSImage.icAttractiveWorldview.swiftUIImage
        case .material:     WSSImage.icAttractiveMaterial.swiftUIImage
        case .writingSkill: WSSImage.icAttractiveWritingSkill.swiftUIImage
        case .character:    WSSImage.icAttractiveCharacter.swiftUIImage
        case .relationship: WSSImage.icAttractiveRelationship.swiftUIImage
        case .vibe:         WSSImage.icAttractiveVibe.swiftUIImage
        }
    }
}
