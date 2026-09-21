//
//  ReadingStatus+NovelDetail.swift
//  NovelDetailFeature
//
//  Created by YunhakLee on 7/10/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import BaseDomain

/// 이 화면이 상태 3분할(평가 셀렉터/상태바)·읽기 상태 그래프에서 공유하는 표시 순서(디자인 고정).
/// 도메인의 `dominantReadingStatusOrder`는 internal이라 재사용할 수 없다.
extension ReadingStatus {
    static let novelDetailDisplayOrder: [ReadingStatus] = [.watching, .watched, .quit]
}
