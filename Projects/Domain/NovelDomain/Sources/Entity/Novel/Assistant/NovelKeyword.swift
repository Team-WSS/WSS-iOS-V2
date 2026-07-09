//
//  NovelKeyword.swift
//  NovelDomain
//
//  Created by YunhakLee on 7/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import Foundation

import BaseDomain

/// 작품 상세의 키워드 항목 — 공통 `Keyword`에 이 작품에서 선택된 횟수를 더한 값.
/// (`UserNovelReview.keywords`는 유저 개인 선택이라 count가 없고 `[Keyword]`를 유지한다.)
public struct NovelKeyword: Equatable, Identifiable {
    public let keyword: Keyword
    public let count: Int

    public var id: KeywordID { keyword.id }

    public init(keyword: Keyword, count: Int) {
        self.keyword = keyword
        self.count = count
    }
}
