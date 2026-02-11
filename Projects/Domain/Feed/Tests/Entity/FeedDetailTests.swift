//
//  FeedDetailTests.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/29/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import FeedDomain
@testable import BaseDomain

@Suite
struct FeedDetailTests {
    
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
        
        #expect(throws: FeedDetail.PolicyError.negativeLikeCount) {
            try mock.toggleLike()
        }
    }
}

extension FeedDetailTests {
    
    private func makeMockConnectedNovel() -> ConnectedNovel {
        ConnectedNovel(
            id: NovelID(3),
            title: "괴담에서 떨어져도 출근을 해야 하는구나",
            genre: .modernFantasy,
            rating: 4.66666)
    }
    
    private func makeMockConnectedNovelDetail() -> ConnectedNovelDetail {
        ConnectedNovelDetail(
            basicInfo: makeMockConnectedNovel(),
            thumbnailImage: ImageWrapper(identifier: "https://test.com"),
            descirption: "안녕하세요",
            feedWriterRating: 2.33333)
    }
    
    private func makeMock(
        _ userId: UserID = UserID(1),
        likeCount: Int = 0,
        isLiked: Bool = false
    ) -> FeedDetail {
        FeedDetail(
            id: FeedID(1),
            author: Author(
                userId: UserID(2),
                nickname: "구리스",
                profileImage: ImageWrapper(identifier: "2")
            ),
            createdDate: "2026-02-06",
            isModified: false,
            feedContent: "content",
            feedImageURLs: [],
            connectedNovel: makeMockConnectedNovelDetail(),
            likeCount: likeCount,
            isLiked: isLiked,
            commentCount: 0
        )
    }
}
