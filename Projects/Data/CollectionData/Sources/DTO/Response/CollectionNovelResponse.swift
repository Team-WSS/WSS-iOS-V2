//
//  CollectionNovelResponse.swift
//  CollectionData
//
//  Created by YunhakLee on 8/18/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// 컬렉션 응답 전반(카드 미리보기·상세 목록)이 공유하는 작품 요약 구조.
public struct CollectionNovelResponse: Decodable {
    public let novelId: Int
    public let title: String
    public let novelImage: String?
    public let author: String
}
