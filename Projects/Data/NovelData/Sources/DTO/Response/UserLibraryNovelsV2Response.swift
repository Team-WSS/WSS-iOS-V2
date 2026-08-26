//
//  UserLibraryNovelsV2Response.swift
//  NovelData
//
//  Created by YunhakLee on 7/21/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// 서재 V2 조회 응답. 아이템 구조는 V1과 동일해 `UserLibraryNovelResponse`를 재사용한다.
struct UserLibraryNovelsV2Response: Decodable {
    public let userNovelCount: Int
    public let isLoadable: Bool
    /// 다음 페이지 요청에 그대로 넘길 서버 발급 커서. 마지막 페이지면 null.
    public let nextCursor: String?
    public let userNovels: [UserLibraryNovelResponse]
}
