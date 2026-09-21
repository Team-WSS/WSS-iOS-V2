//
//  CollectionFeaturePlaceholderTests.swift
//  CollectionFeature
//
//  Created by Claude on 8/26/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import CollectionFeature

// ⚠️ Placeholder — CollectionFeature는 아직 VM 테스트가 없다(골격 단계). 하지만 `.tests` 타깃을
//    유지하려면 Tests/에 **실제로 통과하는 테스트가 최소 1개** 있어야 한다:
//    - Tests/가 아예 비면 `tuist generate`가 "Tests/** 글롭 무효"로 워크스페이스 전체를 깨뜨리고,
//    - `.gitkeep`만 두면 빈 xctest 번들이 런타임에 "실행 파일 없음"으로 로드 실패한다(SettingFeature #210).
//    VM 테스트(#205 축 B-B2)를 추가하면 이 파일은 대체한다. → docs/TODO.md(AI 검증 후속) 1번.
@Suite("CollectionFeature placeholder")
struct CollectionFeaturePlaceholderTests {
    @Test("모듈 테스트 타깃이 빌드·로드된다")
    func moduleTestTargetBuildsAndLoads() {
        #expect(true)
    }
}
