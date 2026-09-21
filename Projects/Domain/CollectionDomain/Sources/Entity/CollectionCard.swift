//
//  CollectionCard.swift
//  CollectionDomain
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

/// 컬렉션 리스트·좋아요한 컬렉션 목록의 카드. 미리보기 썸네일 줄을 보여준다.
///
/// 좋아요 목록 응답에는 `likeCount`가 함께 오지만 그 화면이 좋아요 수를 쓰지 않아 매핑하지 않는다.
/// 필요해지면 이 타입에 더하지 말고 그 화면 전용 타입을 따로 두는 편이 낫다 — 두 목록이 같은 카드를 쓰는 지금 구조가 깨진다.
public struct CollectionCard: Sendable {

    public let id: CollectionID
    public let name: String

    /// 없으면 nil. 서버가 설명 없는 컬렉션에 null을 내려준다.
    public let description: String?

    /// 컬렉션에 든 **전체** 작품 수. `recentNovels.count`가 아니다(미리보기는 최대 5개뿐).
    public let novelCount: Int

    /// "나만 보는 컬렉션" 여부. 서버의 `isPublic`을 뒤집은 값이다 — 기획·화면 용어가 일관되게 "나만 보는"이라
    /// 도메인도 그 방향으로 맞췄다(뒤집기는 Mapper 한 곳에서만 일어난다).
    public let isPrivate: Bool

    /// 저장된 표시 순서 앞에서부터 최대 5개. 대표 작품을 걸러내지 않으므로 대표와 겹칠 수 있다.
    public let recentNovels: [CollectionNovel]

    public init(
        id: CollectionID,
        name: String,
        description: String?,
        novelCount: Int,
        isPrivate: Bool,
        recentNovels: [CollectionNovel]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.novelCount = novelCount
        self.isPrivate = isPrivate
        self.recentNovels = recentNovels
    }
}
