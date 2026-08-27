//
//  KeywordTabContentBuilder.swift
//  SearchFeature
//
//  Created by Seoyeon Choi on 8/13/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain

/// 상세탐색 필터 화면(#185)의 "키워드" 탭 콘텐츠를 **Feature 간 직접 의존 없이** 주입받기 위한 빌더.
///
/// `SearchFeature`는 `KeywordFeature`를 모른다(Feature 간 직접 의존 금지). "키워드" 탭은 "정보" 탭과
/// 진짜 탭바처럼 같은 화면 안에서 콘텐츠만 바뀌어야 하므로(App으로 push하는 방식은 채택하지 않음),
/// 그 콘텐츠 자체를 **호출부(App, Demo에서는 Demo가 App 역할 대행)가 조립해 값으로 건네준다** —
/// "화면 간 이동은 App/조정 계층에서" 원칙을 화면 전환이 아니라 콘텐츠 주입으로 적용한 형태.
///
/// - Parameters:
///   - initialKeywords: 탭 진입 시 이미 선택돼 있던 키워드(`SearchFilter.keywords`) — 콘텐츠에 시딩된다.
///   - onSelectionChanged: 콘텐츠 안에서 선택이 바뀔 때마다(확정 버튼 없이 실시간으로) 호출된다.
///     하단 "작품 찾기" CTA는 이 화면(`DetailSearchFilterView`) 자신이 공용으로 소유한다 —
///     `KeywordFeatureFactory.makeSearchKeywordView`는 애초에 자체 하단 액션바가 없어(`KeywordFeature/CLAUDE.md`
///     참고) 별도 스위치 없이 그대로 주입하면 된다.
public typealias KeywordTabContentBuilder = (
    _ initialKeywords: [Keyword],
    _ onSelectionChanged: @escaping ([Keyword]) -> Void
) -> AnyView
