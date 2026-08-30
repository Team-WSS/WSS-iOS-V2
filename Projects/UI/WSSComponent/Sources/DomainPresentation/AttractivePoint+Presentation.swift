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

public extension AttractivePoint {
    /// 매력포인트 화면 표시 순서(디자인 정본) — `allCases`(enum 선언 순서)와 달리 **필력이 3번째**다.
    /// 매력포인트를 나열하는 모든 화면(감상평 작성·서재 필터)이 이 순서를 공유한다. `NovelGenre.myFeedFilter`
    /// 같은 화면별 표시 순서 배열과 동일한 이유로 순수 enum(BaseDomain)이 아니라 여기(Presentation)에 둔다.
    static let displayOrder: [AttractivePoint] = [
        .worldview, .material, .writingSkill, .character, .relationship, .vibe
    ]

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
