//
//  PublicCollectionsResponse.swift
//  CollectionData
//
//  Created by Guryss on 10/12/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// 전체 공개 컬렉션 목록(`GET /collections`) 응답.
///
/// 사용자별·좋아요 목록(`CollectionsResponse`)과 달리 `collectionsCount`·`isPublic`·`representativeNovel`이 없고
/// `owner`가 있어 DTO를 따로 둔다.
struct PublicCollectionsResponse: Decodable {
    public let collections: [PublicCollectionCardResponse]
    public let hasNext: Bool

    /// hasNext가 false면 null이다.
    public let nextCursor: String?
}

struct PublicCollectionCardResponse: Decodable {
    public let collectionId: Int
    public let collectionName: String
    public let collectionDescription: String?

    /// 컬렉션에 든 전체 작품 수. `recentNovels`의 개수가 아니다.
    public let novelCount: Int

    /// 저장된 표시 순서 앞에서부터 최대 5개. 실제 작품만 담아 5개보다 적을 수 있다.
    public let recentNovels: [CollectionNovelResponse]

    /// 컬렉션 상세의 owner와 같은 구조. 탈퇴한 사용자는 알 수 없는 사용자 프로필로 온다.
    public let owner: CollectionOwnerResponse
}
