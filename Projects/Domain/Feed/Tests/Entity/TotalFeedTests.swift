//
//  TotalFeedTests.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 2/2/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import FeedDomain
@testable import BaseDomain

@Suite
struct TotalFeedTests {
    
    @Test func `좋아요를 누를 수 있다.`() throws {
        var mock = makeMock(likeCount: 3, isLiked: false)
        
        try mock.toggleLike()
        
        #expect(mock.likeCount == 4)
        #expect(mock.isLiked == true)
    }
    
    @Test func `좋아요를 삭제할 수 있다.`() throws {
        var mock = makeMock(likeCount: 3, isLiked: true)
        
        try mock.toggleLike()
        
        #expect(mock.likeCount == 2)
        #expect(mock.isLiked == false)
    }
    
    @Test func `좋아요 수는 음수가 될 수 없다.`() {
        var mock = makeMock(likeCount: 0, isLiked: true)
        
        #expect(throws: TotalFeed.PolicyError.negativeLikeCount) {
            try mock.toggleLike()
        }
    }
}

extension TotalFeedTests {
    private func makeMockConnectedNovel() -> ConnectedNovel {
        ConnectedNovel(
            id: NovelID(3),
            title: "괴담에서 떨어져도 출근을 해야 하는구나",
            genre: .modernFantasy,
            rating: 1.2345)
    }
    
    private func makeMock(
        feedId: FeedID = FeedID(1),
        authorId: UserID = UserID(10),
        likeCount: Int = 0,
        isLiked: Bool = false,
        imageCount: Int = 0,
        thumbnail: ImageWrapper? = nil
    ) -> TotalFeed {
        TotalFeed(
            feedId: feedId,
            createdDate: "2026-02-06",
            content: "테스트 내용",
            author: Author(userId: authorId,
                           nickname: "작성자",
                           profileImage: ImageWrapper(identifier: "")),
            likeCount: likeCount,
            isLiked: isLiked,
            commentCount: 0,
            connectedNovel: makeMockConnectedNovel(),
            isSpoiler: false,
            isModified: false,
            isPublic: true,
            thumbnailImageURL: thumbnail,
            imageCount: imageCount
        )
    }
}
