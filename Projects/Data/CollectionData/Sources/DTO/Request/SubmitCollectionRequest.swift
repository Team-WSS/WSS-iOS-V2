//
//  SubmitCollectionRequest.swift
//  CollectionData
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// 컬렉션 생성·수정이 공유하는 요청 바디.
///
/// 도메인은 "나만 보는"(`isPrivate`) 방향인데 서버는 `isPublic`을 받는다 → 뒤집기는 Mapper가 한 번만 한다.
public struct SubmitCollectionRequest: Encodable {
    public let name: String
    public let description: String?
    public let isPublic: Bool

    /// **배열 순서가 그대로 표시 순서로 저장된다**(앞쪽이 최신). 서버가 재정렬하지 않는다.
    public let novelIds: [Int]

    /// `novelIds`에 포함된 작품이어야 한다(아니면 `COLLECTION-004`).
    public let representativeNovelId: Int
}
