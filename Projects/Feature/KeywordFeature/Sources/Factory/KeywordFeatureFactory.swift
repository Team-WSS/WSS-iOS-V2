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
    @MainActor
    public static func makeSearchKeywordView(
        loadTotalKeywordsUseCase: LoadTotalKeywordsUseCase,
        searchKeywordsUseCase: SearchKeywordsUseCase,
        logger: Logger? = nil
    ) -> some View {
        let viewModel = SearchKeywordViewModel(
            loadTotalKeywordsUseCase: loadTotalKeywordsUseCase,
            searchKeywordsUseCase: searchKeywordsUseCase,
            logger: logger
        )
        return SearchKeywordView(viewModel: viewModel)
    }
}
