//
//  PublicCollectionCard.swift
//  CollectionDomain
//
//  Created by Guryss on 9/28/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

/// 홈 컬렉션 섹션·전체 컬렉션뷰의 카드. 모든 사용자의 공개 컬렉션을 작성자 프로필과 함께 보여준다.
///
/// `CollectionCard`에 `owner`를 옵셔널로 얹지 않고 따로 둔 이유: 사용자별·좋아요 목록은 작성자를 쓰지 않아
/// 두 목록이 같은 카드를 공유하는 구조가 깨진다. 공개 목록만 공개 컬렉션이 오므로 `isPrivate`도 없다.
public struct PublicCollectionCard: Sendable {

    public let id: CollectionID
    public let name: String

    /// 없으면 nil.
    public let description: String?

    /// 컬렉션에 든 **전체** 작품 수. `recentNovels.count`가 아니다(미리보기는 최대 5개뿐).
    public let novelCount: Int

    /// 저장된 표시 순서 앞에서부터 최대 5개. 홈 섹션은 앞 4개만 쓴다.
    public let recentNovels: [CollectionNovel]

    public let owner: Author

    public init(
        id: CollectionID,
        name: String,
        description: String?,
        novelCount: Int,
        recentNovels: [CollectionNovel],
        owner: Author
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.novelCount = novelCount
        self.recentNovels = recentNovels
        self.owner = owner
    }
}
