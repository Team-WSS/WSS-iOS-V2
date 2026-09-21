//
//  CollectionDetailResponse.swift
//  CollectionData
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

struct CollectionDetailResponse: Decodable {
    public let collectionId: Int
    public let collectionName: String
    public let collectionDescription: String?
    public let isPublic: Bool

    /// 조회자가 소유자인지 여부. 비로그인 조회는 항상 false다.
    public let isMyCollection: Bool

    public let owner: CollectionOwnerResponse
    public let representativeNovelId: Int
    public let novelCount: Int
    public let likeCount: Int

    /// 조회자가 좋아요를 눌렀는지 여부. 비로그인 조회는 항상 false다.
    public let isLiked: Bool

    /// 포함 작품 전체. 요청한 정렬 기준으로 정렬돼 오고 페이지네이션이 없다.
    public let novels: [CollectionNovelResponse]
}

struct CollectionOwnerResponse: Decodable {
    public let userId: Int
    public let nickname: String

    /// 아바타는 모든 사용자가 반드시 가지므로 항상 내려온다.
    public let avatarImage: String?
}
