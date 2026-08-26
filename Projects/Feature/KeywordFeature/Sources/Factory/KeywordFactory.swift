//
//  KeywordFactory.swift
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
public enum KeywordFactory {
    /// - `initialSelectedKeywords`: 다른 화면이 이미 선택된 키워드를 들고 진입할 때 시딩(#185).
    /// - `onSelectionChanged`: 선택이 바뀔 때마다(확정 버튼 없이) 실시간으로 호출된다. 이 화면은 자체
    ///   액션바(초기화/선택 완료 버튼)를 갖지 않는다 — 호출부가 자신의 CTA로 초기화·완료를 처리한다.
    @MainActor
    public static func makeSearchKeywordView(
        loadTotalKeywordsUseCase: LoadTotalKeywordsUseCase,
        searchKeywordsUseCase: SearchKeywordsUseCase,
        initialSelectedKeywords: [Keyword] = [],
        onSelectionChanged: (([Keyword]) -> Void)? = nil,
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
            onSelectionChanged: onSelectionChanged
        )
    }
}
