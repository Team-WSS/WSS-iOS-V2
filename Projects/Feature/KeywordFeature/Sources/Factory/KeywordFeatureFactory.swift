//
//  KeywordFeatureFactory.swift
//  KeywordFeature
//
//  Created by Seoyeon Choi on 7/24/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import Logger

/// 모듈의 유일한 public 진입점.
/// View/ViewModel은 internal로 감추고, opaque `some View`로 구체 타입을 숨겨 반환한다.
/// UseCase(프로토콜)는 외부(App/Demo)가 주입한다 — Feature는 Repository/Data 구현을 모른다.
public enum KeywordFeatureFactory {
    /// - `initialSelectedKeywords`: 다른 화면이 이미 선택된 키워드를 들고 진입할 때 시딩(#185).
    /// - `onSelectionChanged`: 선택이 바뀔 때마다(확정 버튼 없이) 실시간으로 호출된다. 이 화면은 자체
    ///   액션바(초기화/선택 완료 버튼)를 갖지 않는다 — 호출부가 자신의 CTA로 초기화·완료를 처리한다.
    /// - `onKeywordCategorySelected`(#249): 브라우징 블록에서 그 카테고리의 칩을 토글할 때마다 호출된다.
    ///   `Keyword` 자체엔 카테고리가 없어(그룹 소속으로만 알 수 있음) 이 화면 안(카테고리별 블록 렌더 지점)에서만
    ///   자연스럽게 알 수 있는 값이라 콜백으로 노출한다 — 이벤트 이름·트래킹 여부는 이 모듈이 모르는 채
    ///   호출부(App)가 정한다(같은 콘텐츠가 탐색 필터·작품 평가 두 문맥에 재사용돼 이벤트 이름이 갈리므로,
    ///   Analytics는 이 모듈이 아니라 호출부가 안다).
    @MainActor
    public static func makeSearchKeywordView(
        loadTotalKeywordsUseCase: LoadTotalKeywordsUseCase,
        searchKeywordsUseCase: SearchKeywordsUseCase,
        initialSelectedKeywords: [Keyword] = [],
        onSelectionChanged: (([Keyword]) -> Void)? = nil,
        onKeywordCategorySelected: ((KeywordCategory) -> Void)? = nil,
        onContactTapped: (() -> Void)? = nil,
        logger: Logger? = nil
    ) -> some View {
        let viewModel = SearchKeywordViewModel(
            loadTotalKeywordsUseCase: loadTotalKeywordsUseCase,
            searchKeywordsUseCase: searchKeywordsUseCase,
            initialSelectedKeywords: initialSelectedKeywords,
            logger: logger
        )
        return SearchKeywordView(
            viewModel: viewModel,
            onSelectionChanged: onSelectionChanged,
            onKeywordCategorySelected: onKeywordCategorySelected,
            onContactTapped: onContactTapped
        )
    }
}
