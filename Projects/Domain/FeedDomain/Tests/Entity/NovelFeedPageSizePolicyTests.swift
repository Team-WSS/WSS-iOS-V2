//
//  NovelFeedPageSizePolicyTests.swift
//  FeedDomain
//
//  Created by YunhakLee on 9/1/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation
import Testing

@testable import FeedDomain

@Suite
struct NovelFeedPageSizePolicyTests {

    @Test("아직 받은 피드가 없으면 nil을 반환해 기본 페이지 크기에 맡긴다")
    func refreshSizeWithNothingLoadedFallsBackToDefault() {
        #expect(NovelFeedPageSizePolicy.refreshSize(loadedCount: 0) == nil)
    }

    @Test("보고 있던 개수를 그대로 요청 크기로 쓴다")
    func refreshSizeKeepsLoadedCount() {
        #expect(NovelFeedPageSizePolicy.refreshSize(loadedCount: 1) == 1)
        #expect(NovelFeedPageSizePolicy.refreshSize(loadedCount: 37) == 37)
        #expect(NovelFeedPageSizePolicy.refreshSize(loadedCount: 100) == 100)
    }

    @Test("서버 상한(100)을 넘겨 본 상태에서는 상한으로 자른다")
    func refreshSizeClampsToServerMax() {
        #expect(NovelFeedPageSizePolicy.refreshSize(loadedCount: 101) == 100)
        #expect(NovelFeedPageSizePolicy.refreshSize(loadedCount: 250) == 100)
    }
}
