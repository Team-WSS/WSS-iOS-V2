//
//  NovelDetailFeatureTests.swift
//  NovelDetailFeature
//
//  Created by YunhakLee on 7/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing

@testable import NovelDetailFeature

// Tests/** 글롭 매칭용 placeholder. Feature 테스트는 강제 대상이 아니나(테스트 의무는 Domain 한정),
// 경합 가드(닫기 중 로드 완료)·관심 낙관 토글/롤백·커서 페이지네이션 가드는 mock UseCase 주입으로
// 명세화할 가치가 높다 — 후속 이슈에서 보강 권장.
@Suite("NovelDetailFeature")
struct NovelDetailFeatureTests {

    @Test("모듈 타깃이 컴파일된다")
    func moduleCompiles() {
        #expect(Bool(true))
    }
}
