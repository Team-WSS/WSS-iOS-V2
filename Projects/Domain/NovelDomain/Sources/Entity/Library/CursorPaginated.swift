//
//  CursorPaginated.swift
//  NovelDomain
//
//  Created by YunhakLee on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// 서버가 발급한 불투명 커서(`nextCursor`)로 다음 페이지를 잇는 페이지네이션 래퍼.
///
/// `Paginated<T>`(hasNext만 보유)로는 다음 요청에 넘길 커서를 표현할 수 없어 분리했다.
/// 마지막 아이템 ID로 커서를 유도하지 말 것 — 커서는 서버 발급 값 그대로 왕복한다.
/// (현재 서재 전용. 다른 도메인도 쓰게 되면 BaseDomain 승격 검토.)
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
