//
//  NovelPlatform.swift
//  SearchDomain
//
//  Created by Seoyeon Choi on 8/13/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

/// 상세탐색 필터(`SearchFilter`) 전용 플랫폼 목록. 작품 상세의 `NovelDomain.NovelPlatform`(표지·URL 포함)과는
/// 별개 — 이쪽은 필터 선택지로 쓸 고정 5종만 표현한다.
/// 선언 순서 = Figma 노출 순서(`CaseIterable`이 그대로 표시 순서로 쓰인다).
public enum NovelPlatform: CaseIterable, Equatable, Sendable {
    case kakaoPage
    case naverSeries
    case ridibooks
    case munpia
    case novelpia
}
