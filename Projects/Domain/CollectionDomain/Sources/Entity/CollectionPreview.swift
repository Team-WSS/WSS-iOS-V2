//
//  CollectionPreview.swift
//  CollectionDomain
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

/// 마이페이지 컬렉션 섹션의 카드. 대표 작품 표지 하나만 보여준다.
///
/// 전용 API가 있는 게 아니라 사용자별 컬렉션 목록을 `size=3`으로 호출해 구성한다(서버 명세 지침).
/// 같은 응답을 쓰는 `CollectionCard`와 나눠 둔 이유는 서버가 `representativeNovel`과 `recentNovels`를
/// **둘 다** 내려주고 "무엇을 쓸지는 화면이 정하라"고 위임하기 때문이다 —
/// 그 선택을 화면마다 반복하지 않도록 매핑 시점에 한 번 고정한다.
public struct CollectionPreview: Sendable {

    public let id: CollectionID
    public let name: String

    /// 카드 표지로 쓰는 대표 작품. `recentNovels`와 독립적인 값이라 목록에 포함될 수도, 아닐 수도 있다.
    public let representativeNovel: CollectionNovel

    public init(
        id: CollectionID,
        name: String,
        representativeNovel: CollectionNovel
    ) {
        self.id = id
        self.name = name
        self.representativeNovel = representativeNovel
    }
}
