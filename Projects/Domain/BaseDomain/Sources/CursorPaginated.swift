//
//  CursorPaginated.swift
//  BaseDomain
//
//  Created by YunhakLee on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// 서버가 발급한 불투명 커서(`nextCursor`)로 다음 페이지를 잇는 페이지네이션 래퍼.
///
/// `Paginated<T>`(hasNext만 보유)로는 다음 요청에 넘길 커서를 표현할 수 없어 분리했다.
/// 마지막 아이템 ID로 커서를 유도하지 말 것 — 커서는 서버 발급 값 그대로 왕복한다.
/// 서재(NovelDomain)에 이어 컬렉션도 같은 방식이라 BaseDomain으로 승격했다(#191).
/// 단, `Paginated<T>`를 이걸로 통합하지는 말 것 — 피드는 `lastFeedId`(클라이언트가 마지막 항목에서 유도),
/// 검색은 `page`/`size` 오프셋이라 넘길 커서가 없어서 `nextCursor`가 항상 nil인 껍데기가 된다.
public struct CursorPaginated<T> {
    public let items: [T]
    public let hasNext: Bool
    public let nextCursor: String?

    public init(items: [T], hasNext: Bool, nextCursor: String?) {
        self.items = items
        self.hasNext = hasNext
        self.nextCursor = nextCursor
    }
}

extension CursorPaginated: Sendable where T: Sendable {}
