//
//  AttractivePoint.swift
//  BaseDomain
//
//  Created by YunhakLee on 1/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// 케이스 선언 순서가 곧 화면 표시 순서(디자인 정본 — 필력이 3번째)다.
/// 작품 평가·서재 필터·서재 리스트 셀이 전부 `allCases` 순서를 공유하므로 순서를 함부로 바꾸지 말 것.
public enum AttractivePoint: Equatable, CaseIterable, Sendable {
    case worldview
    case material
    case writingSkill
    case character
    case relationship
    case vibe
}
