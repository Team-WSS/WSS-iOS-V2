//
//  CollectionsResponse.swift
//  CollectionData
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// 컬렉션 목록(사용자별·좋아요한) 공통 응답.
///
/// 두 API의 카드 구조는 `likeCount` 하나만 다르다(좋아요한 목록에만 온다) → optional로 두고 한 DTO로 받는다.
public struct CollectionsResponse: Decodable {
    public let collections: [CollectionCardResponse]
    public let hasNext: Bool
    public let nextCursor: String?

    /// 조회자가 볼 수 있는 **전체** 컬렉션 수. 이번 페이지 개수가 아니다.
    public let collectionsCount: Int
}

public struct CollectionCardResponse: Decodable {
    public let collectionId: Int
    public let collectionName: String
    public let collectionDescription: String?
    public let isPublic: Bool

    /// 컬렉션에 든 전체 작품 수. `recentNovels`의 개수가 아니다.
    public let novelCount: Int

    /// 카드 표지로 쓰는 대표 작품. `recentNovels`와 독립적이라 둘에 같은 작품이 들어올 수 있다.
    public let representativeNovel: CollectionNovelResponse

    /// 저장된 표시 순서 앞에서부터 최대 5개.
    public let recentNovels: [CollectionNovelResponse]

    /// 좋아요한 컬렉션 목록에만 내려온다. 현재 화면이 쓰지 않아 매핑하지 않는다.
    public let likeCount: Int?
}
