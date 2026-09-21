//
//  KeywordSearchSheetBuilder.swift
//  NovelReviewFeature
//
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain

/// 키워드 탐색 시트 콘텐츠 주입 — `NovelReviewFeature`는 `KeywordFeature`를 모른다(Feature 간 직접
/// 의존 금지). App이 `KeywordFeatureFactory.makeSearchKeywordView`로 조립한 `AnyView`를 값으로 건넨다.
/// `SearchFeature`의 `KeywordTabContentBuilder`와 같은 형태·같은 이유(조립 seam은 `Navigation/`에 —
/// arch-lint `feature-exclusivity`가 이 폴더의 public만 진입점 외 예외로 허용한다).
///
/// `SearchKeywordView` 자신은 하단 액션 바가 없어 `onSelectionChanged`로 선택을 실시간 보고만 한다 —
/// 확인/닫기는 이 빌더를 감싸는 쪽(`NovelReviewView`)이 책임진다.
public typealias KeywordSearchSheetBuilder = (
    _ initialKeywords: [Keyword],
    _ onSelectionChanged: @escaping ([Keyword]) -> Void
) -> AnyView
