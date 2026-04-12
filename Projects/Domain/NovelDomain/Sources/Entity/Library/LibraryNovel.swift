//
//  LibraryNovel.swift
//  NovelDomain
//
//  Created by Seoyeon Choi on 2/22/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

public struct LibraryNovel {
    
    // 작품 정보
    public let id: NovelID
    public let title: String
    public let thumbnailImage: URL?
    public let rating: Float
    public let isInterested: Bool
    
    // 유저의 작품 평가
    public let userReview: UserNovelReview?
    
    // 유저가 작품에 남긴 피드
    public let writtenFeeds: [String]
    
    public init(
        id: NovelID,
        title: String, 
        thumbnailImage: URL?,
        rating: Float,
        isInterested: Bool,
        userReview: UserNovelReview?,
        writtenFeeds: [String]
    ) {
        self.id = id
        self.title = title
        self.thumbnailImage = thumbnailImage
        self.rating = rating
        self.isInterested = isInterested
        self.userReview = userReview
        self.writtenFeeds = writtenFeeds
    }
}
