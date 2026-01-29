//
//  FeedDetailPolicyTests.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/29/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import FeedDomain

@Suite
struct FeedDetailPolicyTests {
    @Suite("FeedDetail Image Display Policy Tests")
    struct FeedDetailImageDisplayPolicyTests {
        
        @Test
        func imageDisplayStyle_returnsNone_whenImageCountIsZero() {
            let result = FeedDetailEntity.imageDisplayStyle(for: 0)
            #expect(result == .none)
        }
        
        @Test
        func imageDisplayStyle_returnsSingle_whenImageCountIsOne() {
            let result = FeedDetailEntity.imageDisplayStyle(for: 1)
            #expect(result == .single)
        }
        
        @Test
        func imageDisplayStyle_returnsHorizontalScroll_whenImageCountIsMoreThanOne() {
            let result = FeedDetailEntity.imageDisplayStyle(for: 3)
            #expect(result == .horizontalScroll)
        }
    }
    
    @Suite("FeedDetail More Action Policy Tests")
    struct FeedDetailMoreActionPolicyTests {
        
        @Test
        func availableMoreActions_returnsMyFeed_whenFeedIsMine() {
            let result = FeedDetailEntity.availableMoreActions(isMyFeed: true)
            #expect(result == .myFeed)
        }
        
        @Test
        func availableMoreActions_returnsOtherUserFeed_whenFeedIsNotMine() {
            let result = FeedDetailEntity.availableMoreActions(isMyFeed: false)
            #expect(result == .otherUserFeed)
        }
    }
    
}
