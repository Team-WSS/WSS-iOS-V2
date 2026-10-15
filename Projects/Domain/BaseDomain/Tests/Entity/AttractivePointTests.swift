//
//  AttractivePointTests.swift
//  BaseDomain
//
//  Created by YunhakLee on 9/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

import BaseDomain

@Suite("매력 포인트")
struct AttractivePointTests {

    @Test("매력 포인트는 디자인이 정한 순서대로 보인다")
    func followsDesignOrder() {
        // 작품 평가·서재 필터·서재 목록 셀이 따로 정한 순서 없이 선언 순서를 그대로 쓴다(#256).
        // 선언 순서를 바꾸면 컴파일도 다른 테스트도 통과한 채 세 화면의 순서가 한꺼번에 바뀐다.
        let order = AttractivePoint.allCases

        #expect(order == [
            .worldview,
            .material,
            .writingSkill,
            .character,
            .relationship,
            .vibe,
        ])
    }
}
