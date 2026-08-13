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
    /// - `showsBottomActionBar`: 기본 `true`(독립 화면, 자체 초기화/N개 선택 하단바). 다른 화면의 탭 콘텐츠로
    ///   얹힐 때는 `false`로 감추고 `onSelectionChanged`로 실시간 반영한다 — 호출부가 자기 CTA를 갖고 있어서다.
    /// - `onComplete`: 하단 "N개 선택" 확정 시 호출(화면을 닫는 건 호출부 책임, `LibraryFilterSheet`의 `onApply`
    ///   패턴과 동일). `showsBottomActionBar: false`면 그 버튼 자체가 없어 호출되지 않는다.
    @MainActor
    public static func makeSearchKeywordView(
        loadTotalKeywordsUseCase: LoadTotalKeywordsUseCase,
        searchKeywordsUseCase: SearchKeywordsUseCase,
        initialSelectedKeywords: [Keyword] = [],
        showsBottomActionBar: Bool = true,
        onSelectionChanged: (([Keyword]) -> Void)? = nil,
        onComplete: @escaping ([Keyword]) -> Void = { _ in },
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
            showsBottomActionBar: showsBottomActionBar,
            onSelectionChanged: onSelectionChanged,
            onComplete: onComplete
        )
    }
}
