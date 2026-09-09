//
//  AttractivePointTests.swift
//  BaseDomain
//
//  Created by YunhakLee on 9/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import BaseDomain

@Suite
struct AttractivePointTests {

    // MARK: - 표시 순서 계약

    @Test("케이스 선언 순서가 곧 화면 표시 순서다 — 필력이 3번째(디자인 정본, #256)")
    func allCasesFollowDesignOrder() {
        // 작품 평가·서재 필터·서재 리스트 셀이 별도 순서 배열 없이 allCases 순서를 그대로 공유한다
        // (#256에서 WSSComponent의 displayOrder 배열을 지우고 enum 선언 순서를 유일한 정본으로 승격).
        // 케이스를 재정렬하거나 추가하면 컴파일·기존 테스트 모두 초록인 채 세 화면의 순서가 통째로
        // 바뀌므로, 이 테스트가 그 계약을 고정한다 — 순서를 바꾸려면 디자인 확정과 함께 여기도 갱신할 것.
        #expect(AttractivePoint.allCases == [
            .worldview,
            .material,
            .writingSkill,
            .character,
            .relationship,
            .vibe,
        ])
    }
}
