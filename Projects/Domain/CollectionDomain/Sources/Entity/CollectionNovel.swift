//
//  CollectionNovel.swift
//  CollectionDomain
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

/// 컬렉션에 담긴 작품. 서버가 컬렉션 응답 전반(카드 미리보기·상세 목록)에서 쓰는 작품 요약 구조다.
///
/// `BaseDomain`의 `Novel`을 재사용하지 않는 이유: 컬렉션 화면은 평점·관심수·장르를 쓰지 않고
/// 서버도 내려주지 않는다. `Novel`을 쓰면 매핑에서 없는 값을 0으로 채워 넣게 된다.
///
/// `Hashable`(#201) — 필드가 전부 이미 Hashable(`NovelID`/`String`/`URL?`)이라 자동 합성만으로
/// 충분했다. `CollectionDetail.owner: Author`와 달리 이 타입은 `Author`를 담지 않아 캐스케이드가
/// 없다(`CollectionFeature/CLAUDE.md`의 "App `NavigationPath` 항목 payload" 참고 — `CollectionDetail`
/// 전체를 Hashable로 만들려던 시도는 `Author`까지 끌고 가 보류됐지만, 이 타입 단독은 안전하다).
public struct CollectionNovel: Hashable, Sendable {

    public let id: NovelID
    public let title: String
    public let author: String
    public let thumbnailImage: URL?

    public init(
        id: NovelID,
        title: String,
        author: String,
        thumbnailImage: URL?
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.thumbnailImage = thumbnailImage
    }
}
