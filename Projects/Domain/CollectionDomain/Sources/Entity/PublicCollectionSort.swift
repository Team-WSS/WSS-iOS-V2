//
//  PublicCollectionSort.swift
//  CollectionDomain
//
//  Created by YunhakLee on 11/27/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// 전체 공개 컬렉션 목록(`GET /collections`)의 정렬 기준.
public enum PublicCollectionSort: Sendable {
    /// 최초 생성 시점 최신순. 수정·작품 재배치·좋아요로 순서가 바뀌지 않는다. 커서로 이어 받는다.
    case latest
    /// 공개·차단 조건을 통과한 전체 후보에서 중복 없이 무작위로 고른 **한 페이지**.
    /// 페이지네이션이 없어 커서를 함께 보내면 서버가 거부한다(빈 값이어도 400).
    /// 요청마다 새로 고르지만 매번 달라진다고 보장하지는 않는다.
    case random
}
