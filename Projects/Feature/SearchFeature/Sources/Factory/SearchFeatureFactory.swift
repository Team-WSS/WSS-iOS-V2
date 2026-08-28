//
//  SearchFeatureFactory.swift
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
/// (`Feature CLAUDE.md`의 Factory 규칙). `makeDetailSearchFilterView`는 실제 앱 흐름에서는 쓰이지 않는다 —
/// 지금 `DetailSearchFilterView`를 push하는 건 Demo의 상세탐색 진입 흐름뿐이다(SearchFeature/CLAUDE.md
/// "필터 화면 진입·복귀" 참고). Demo에서 단독으로 열어 검증할 수 있도록 여기도 노출한다.
/// `makeDetailSearchResultView`는 반대로 Demo 전용이 아니라 App도 실사용하는 독립 진입점이다(#196부터,
/// "화면 간 이동" 참고).
public enum SearchFeatureFactory {

    /// - Parameters:
    ///   - onNovelSelected: 검색 결과·소소픽 작품 셀 탭 → 작품 상세 진입 콜백. 실제 화면 전환은
    ///     호출자(App 조정 계층)가 수행한다.
    ///   - onDetailSearchRequested: 장르 탭·인기 키워드 칩 탭 → 상세탐색 결과(`makeDetailSearchResultView`)
    ///     진입 콜백. 실제 화면 전환은 호출자(App 조정 계층)가 수행한다 — `NavigationPath` 혼용으로 화면이
    ///     안 쌓이는 문제 때문에 App이 직접 push해야 한다(`makeDetailSearchResultView` 참고).
    ///   - initialQuery: 비어있지 않으면 화면이 뜨자마자 이 텍스트로 검색을 실행해 결과부터 보여준다
    ///     (예: 작가 이름 탭 → 그 작가로 사전 검색된 결과 화면). `nil`(기본값)이면 평소처럼 빈 검색창.
    @MainActor
    public static func makeNormalSearchView(
        loadSosoPickUseCase: LoadSosoPickUseCase,
        loadRecentSearchWordsUseCase: LoadRecentSearchWordsUseCase,
        removeRecentSearchWordUseCase: RemoveRecentSearchWordUseCase,
        clearRecentSearchWordsUseCase: ClearRecentSearchWordsUseCase,
        searchAutoCompletionWordsUseCase: SearchAutoCompletionWordsUseCase,
        searchNovelUseCase: SearchNovelUseCase,
        loadPopularKeywordsUseCase: LoadPopularKeywordsUseCase,
        logger: Logger? = nil,
        initialQuery: String? = nil,
        onNovelSelected: @escaping (NovelID) -> Void = { _ in },
        onDetailSearchRequested: @escaping (SearchFilter) -> Void = { _ in }
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
                logger: logger,
                initialQuery: initialQuery
            ),
            onNovelSelected: onNovelSelected,
            onDetailSearchRequested: onDetailSearchRequested
        )
    }

    /// 상세탐색 필터 화면 단독 진입 — UseCase가 없는 순수 입력 화면이라 필터 값과 콜백만 받는다.
    /// `keywordTabContent` — "키워드" 탭 콘텐츠를 조립하는 빌더. `SearchFeature`는 `KeywordFeature`를
    /// 모르므로 App/Demo가 `KeywordFeatureFactory.makeSearchKeywordView(...)`를 감싸 건네준다 — 계약은
    /// `KeywordTabContentBuilder` 문서 참고.
    @MainActor
    public static func makeDetailSearchFilterView(
        filter: SearchFilter = SearchFilter(),
        keywordTabContent: @escaping KeywordTabContentBuilder,
        onSearch: @escaping (SearchFilter) -> Void
    ) -> some View {
        DetailSearchFilterView(filter: filter, keywordTabContent: keywordTabContent, onSearch: onSearch)
    }

    /// 상세탐색 결과(장르·키워드 필터 검색 그리드) — App이 `onDetailSearchRequested`를 받아 자기
    /// `NavigationPath`로 push할 때 이 메서드로 조립한다(#196). `NormalSearchView`가 내부에서 직접 push하지
    /// 않는 이유는 `makeNormalSearchView`의 `onDetailSearchRequested` doc 참고. Demo도 `makeDetailSearchFilterView`의
    /// "작품 찾기"를 실제 검색으로 이어 검증할 때 이 메서드를 그대로 쓴다.
    ///
    /// - Parameter onNovelSelected: 작품 셀 탭 → 작품 상세 진입 콜백. `makeNormalSearchView`와 같은 콜백을
    ///   그대로 재사용해도 되고(같은 `NavigationPath`에 같은 방식으로 push), 화면마다 다르게 줘도 된다.
    @MainActor
    public static func makeDetailSearchResultView(
        filter: SearchFilter,
        searchNovelUseCase: SearchNovelUseCase,
        logger: Logger? = nil,
        onNovelSelected: @escaping (NovelID) -> Void = { _ in }
    ) -> some View {
        DetailSearchResultView(
            viewModel: DetailSearchResultViewModel(
                filter: filter,
                searchNovelUseCase: searchNovelUseCase,
                logger: logger
            ),
            onNovelSelected: onNovelSelected
        )
    }
}
