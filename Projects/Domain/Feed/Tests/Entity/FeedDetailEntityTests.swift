//
//  FeedDetailEntityTests.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/29/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import FeedDomain
 
@Suite
struct FeedDetailEntityTests {
    @Test
    func feedDetailEntity_initializesCorrectly() {
        let entity = FeedDetail(
            userId: UserID(1),
            userProfileImageURL: nil,
            userName: "서연",
            createdDate: "2026-01-01",
            isModified: false,
            feedContent: "피드 본문",
            feedImageURLs: [],
            connectedNovel: nil,
            likeCount: 10,
            isLiked: false,
            commentCount: 3
        )

        #expect(entity.userName == "서연")
        #expect(entity.likeCount == 10)
        #expect(entity.isLiked == false)
    }
}
