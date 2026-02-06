//
//  FeedDetailTests.swift
//  FeedDomain
//
//  Created by Seoyeon Choi on 1/29/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Testing
@testable import FeedDomain

@Suite
struct FeedDetailTests {
    @Test func `연결 작품의 전체 별점은 소수 첫째자리까지 나타낸다.`() {
        var mock = makeMock().connectedNovel?.basicInfo
        
        mock?.roundedRating()
        
        #expect(mock?.rating == 4.7)
    }
    
    @Test func `연결 작품의 피드 작성자 별점은 소수 첫째자리까지 나타낸다.`() {
        var mock = makeMock().connectedNovel
        
        mock?.roundedRating()
        
        #expect(mock?.feedWriterRating == 2.3)
    }
    
    @Test func `좋아요를 누를 수 있다.`() {
        var mock = makeMock(likeCount: 3, isLiked: false)
        
        mock.addLike()
        
        #expect(mock.likeCount == 4)
        #expect(mock.isLiked == true)
    }
    
    @Test func `좋아요를 삭제할 수 있다.`() throws {
        var mock = makeMock(likeCount: 3, isLiked: true)
        
        try mock.removeLike()
        
        #expect(mock.likeCount == 2)
        #expect(mock.isLiked == false)
    }
    
    @Test func `좋아요를 안 눌렀을 때 좋아요를 삭제할 수 없다.`() throws {
        var mock = makeMock(likeCount: 3, isLiked: false)
        
        #expect(throws: FeedDetail.PolicyError.notLikedYet) {
            try mock.removeLike()
        }
    }
    
    @Test func `좋아요 수는 음수가 될 수 없다.`() {
        var mock = makeMock(likeCount: 0, isLiked: true)
        
        #expect(throws: FeedDetail.PolicyError.negativeLikeCount) {
            try mock.removeLike()
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
            descirption: "안녕하세요",
            feedWriterRating: 2.33333)
    }
    
    private func makeMock(
        _ userId: UserID = UserID(1),
        likeCount: Int = 0,
        isLiked: Bool = false
    ) -> FeedDetail {
        FeedDetail(
            userId: userId,
            userProfileImageURL: ImageWrapper(identifier: "https://test.com"),
            userName: "tester",
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
