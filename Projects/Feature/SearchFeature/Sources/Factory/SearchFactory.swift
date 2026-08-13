//
//  SearchFactory.swift
//  SearchFeature
//
//  Created by Seoyeon Choi on 7/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import RecommendationDomain
import SearchDomain
import Logger

/// 모듈의 public 진입점 — 화면이 대등하게 둘이라 전부 `makeXxxView`로 무엇을 만드는지 이름에 넣는다
/// (`Feature CLAUDE.md`의 Factory 규칙). `makeDetailSearchFilterView`는 실제 앱 흐름에서는
/// `NormalSearchView`가 내부에서 조립해 쓰지만(`DetailSearchResultView`의 필터 요약 pill), Demo에서
/// 단독으로 열어 검증할 수 있도록 여기도 노출한다.
public enum SearchFactory {

    @MainActor
    public static func makeNormalSearchView(
        loadSosoPickUseCase: LoadSosoPickUseCase,
        loadRecentSearchWordsUseCase: LoadRecentSearchWordsUseCase,
        removeRecentSearchWordUseCase: RemoveRecentSearchWordUseCase,
        clearRecentSearchWordsUseCase: ClearRecentSearchWordsUseCase,
        searchAutoCompletionWordsUseCase: SearchAutoCompletionWordsUseCase,
        searchNovelUseCase: SearchNovelUseCase,
        loadPopularKeywordsUseCase: LoadPopularKeywordsUseCase,
        logger: Logger? = nil
    ) -> some View {
        NormalSearchView(
            viewModel: NormalSearchViewModel(
                loadSosoPickUseCase: loadSosoPickUseCase,
                loadRecentSearchWordsUseCase: loadRecentSearchWordsUseCase,
                removeRecentSearchWordUseCase: removeRecentSearchWordUseCase,
                clearRecentSearchWordsUseCase: clearRecentSearchWordsUseCase,
                searchAutoCompletionWordsUseCase: searchAutoCompletionWordsUseCase,
                searchNovelUseCase: searchNovelUseCase,
                loadPopularKeywordsUseCase: loadPopularKeywordsUseCase,
                logger: logger
            )
        )
    }

    /// 상세탐색 필터 화면 단독 진입 — UseCase가 없는 순수 입력 화면이라 필터 값과 콜백만 받는다.
    @MainActor
    public static func makeDetailSearchFilterView(
        filter: SearchFilter = SearchFilter(),
        onSearch: @escaping (SearchFilter) -> Void
    ) -> some View {
        DetailSearchFilterView(filter: filter, onSearch: onSearch)
    }
}
