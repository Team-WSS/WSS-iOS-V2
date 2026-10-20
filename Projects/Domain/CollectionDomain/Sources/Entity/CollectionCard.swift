//
//  CollectionCard.swift
//  CollectionDomain
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

/// 컬렉션 목록 카드. 사용자별·좋아요한 목록과 공개 목록(홈 섹션·전체 컬렉션뷰)이 함께 쓴다. 미리보기 썸네일 줄을 보여준다.
///
/// 세 목록이 다루는 정보가 겹쳐 한 타입으로 통합했다. 서버가 소유자를 공개 목록에만 내려줘 `owner`는 옵셔널이다.
/// 좋아요 목록 응답의 `likeCount`는 쓰는 화면이 없어 매핑하지 않는다.
public struct CollectionCard: Sendable {

    public let id: CollectionID
    public let name: String

    /// 없으면 nil. 서버가 설명 없는 컬렉션에 null을 내려준다.
    public let description: String?

    /// 컬렉션에 든 **전체** 작품 수. `recentNovels.count`가 아니다(미리보기는 최대 5개뿐).
    public let novelCount: Int

    /// "나만 보는 컬렉션" 여부. 서버의 `isPublic`을 뒤집은 값이다 — 기획·화면 용어가 일관되게 "나만 보는"이라
    /// 도메인도 그 방향으로 맞췄다(뒤집기는 Mapper 한 곳에서만 일어난다).
    /// 다른 사람의 나만 보는 컬렉션은 조회되지 않으므로, 남의 컬렉션이거나 서버가 공개 여부를 주지 않으면 false다.
    public let isPrivate: Bool

    /// 작성자. 서버가 소유자를 내려주는 공개 목록에서만 있고, 사용자별·좋아요 목록은 nil이다.
    public let owner: Author?

    /// 로그인 사용자 소유 여부. 소유자 ID를 로그인 사용자 ID와 비교해 Repository가 정한다.
    /// 좋아요 목록은 소유자를 알 수 없어 항상 false다.
    public let isMine: Bool

    /// 저장된 표시 순서 앞에서부터 최대 5개. 대표 작품을 걸러내지 않으므로 대표와 겹칠 수 있다.
    public let recentNovels: [CollectionNovel]

    public init(
        id: CollectionID,
        name: String,
        description: String?,
        novelCount: Int,
        isPrivate: Bool,
        recentNovels: [CollectionNovel],
        owner: Author? = nil,
        isMine: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.novelCount = novelCount
        self.isPrivate = isPrivate
        self.recentNovels = recentNovels
        self.owner = owner
        self.isMine = isMine
    }
}
