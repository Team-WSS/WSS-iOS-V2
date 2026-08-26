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
/// (`Feature CLAUDE.md`의 Factory 규칙). `makeDetailSearchFilterView`/`makeDetailSearchResultView`는
/// 실제 앱 흐름에서는 `NormalSearchView`/`DetailSearchResultView`가 내부에서 조립해 쓰지 않는다 — 지금
/// `DetailSearchFilterView`를 push하는 건 Demo의 상세탐색 진입 흐름뿐이다(SearchFeature/CLAUDE.md
/// "필터 화면 진입·복귀" 참고). Demo에서 단독으로 열어 검증할 수 있도록 여기도 노출한다.
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
    /// `keywordTabContent` — "키워드" 탭 콘텐츠를 조립하는 빌더. `SearchFeature`는 `KeywordFeature`를
    /// 모르므로 App/Demo가 `KeywordFactory.makeSearchKeywordView(...)`를 감싸 건네준다 — 계약은
    /// `KeywordTabContentBuilder` 문서 참고.
    @MainActor
    public static func makeDetailSearchFilterView(
        filter: SearchFilter = SearchFilter(),
        keywordTabContent: @escaping KeywordTabContentBuilder,
        onSearch: @escaping (SearchFilter) -> Void
    ) -> some View {
        DetailSearchFilterView(filter: filter, keywordTabContent: keywordTabContent, onSearch: onSearch)
    }

    /// 상세탐색 결과 화면 단독 진입 — 실제 앱 흐름에서는 `NormalSearchView`가 내부에서 조립해 쓰지만
    /// (장르/키워드 탭 진입), `makeDetailSearchFilterView`의 "작품 찾기"를 실제 검색으로 이어 Demo에서
    /// 검증할 수 있도록 여기도 노출한다.
    @MainActor
    public static func makeDetailSearchResultView(
        filter: SearchFilter,
        searchNovelUseCase: SearchNovelUseCase,
        logger: Logger? = nil
    ) -> some View {
        DetailSearchResultView(
            viewModel: DetailSearchResultViewModel(
                filter: filter,
                searchNovelUseCase: searchNovelUseCase,
                logger: logger
            )
        )
    }
}
