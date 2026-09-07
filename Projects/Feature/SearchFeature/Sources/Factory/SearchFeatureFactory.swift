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
import Analytics

/// 모듈의 public 진입점 — 화면이 대등하게 둘이라 전부 `makeXxxView`로 무엇을 만드는지 이름에 넣는다
/// (`Feature CLAUDE.md`의 Factory 규칙). `makeDetailSearchFilterView`는 #201부터 App(`SearchAssembly`)도
/// 실사용한다 — 홈 배너와 일반 검색의 "더보기" 헤더(#236)가 이 화면을 push한다(SearchFeature/CLAUDE.md
/// "필터 화면 진입·복귀" 참고). `makeDetailSearchResultView`도 App이 실사용하는 독립 진입점이다(#196부터,
/// "화면 간 이동" 참고).
public enum SearchFeatureFactory {

    /// - Parameters:
    ///   - initialQuery: 비어있지 않으면 화면이 뜨자마자 이 텍스트로 검색을 실행해 결과부터 보여준다
    ///     (예: 작가 이름 탭 → 그 작가로 사전 검색된 결과 화면). `nil`(기본값)이면 평소처럼 빈 검색창.
    ///   - onRoute: 화면 전환 의도 콜백 — 목적지·payload는 `NormalSearchRoute`(Navigation/) 참고.
    ///     실제 화면 조립·push는 호출자(App 조정 계층)가 exhaustive switch로 수행한다(#253).
    ///     기본값 no-op를 두지 않는다 — 배선 누락이 조용히 삼켜지는 걸 컴파일러가 막게 한다.
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
        analyticsTracker: AnalyticsTracker? = nil,
        initialQuery: String? = nil,
        onRoute: @escaping (NormalSearchRoute) -> Void
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
                analyticsTracker: analyticsTracker,
                initialQuery: initialQuery
            ),
            onRoute: onRoute
        )
    }

    /// 상세탐색 필터 화면 단독 진입 — UseCase가 없는 순수 입력 화면이라 필터 값과 콜백만 받는다.
    /// `keywordTabContent` — "키워드" 탭 콘텐츠를 조립하는 빌더. `SearchFeature`는 `KeywordFeature`를
    /// 모르므로 App/Demo가 `KeywordFeatureFactory.makeSearchKeywordView(...)`를 감싸 건네준다 — 계약은
    /// `KeywordTabContentBuilder` 문서 참고.
    @MainActor
    public static func makeDetailSearchFilterView(
        filter: SearchFilter = SearchFilter(),
        initialTab: DetailSearchFilterTab = .info,
        keywordTabContent: @escaping KeywordTabContentBuilder,
        onSearch: @escaping (SearchFilter) -> Void,
        analyticsTracker: AnalyticsTracker? = nil
    ) -> some View {
        DetailSearchFilterView(
            filter: filter,
            initialTab: initialTab,
            keywordTabContent: keywordTabContent,
            onSearch: onSearch,
            analyticsTracker: analyticsTracker
        )
    }

    /// 상세탐색 결과(장르·키워드 필터 검색 그리드) — App이 `NormalSearchRoute.detailSearchResult`를 받아
    /// 자기 `NavigationPath`로 push할 때 이 메서드로 조립한다(#196). `NormalSearchView`가 내부에서 직접
    /// push하지 않는 이유는 `NormalSearchRoute.detailSearchResult`의 doc 참고. Demo도 `makeDetailSearchFilterView`의
    /// "작품 찾기"를 실제 검색으로 이어 검증할 때 이 메서드를 그대로 쓴다.
    ///
    /// - Parameter onRoute: 화면 전환 의도 콜백(`DetailSearchResultRoute`) — 실제 push는 호출자(App)가
    ///   수행한다(#253). 기본값 no-op를 두지 않는다.
    @MainActor
    public static func makeDetailSearchResultView(
        filter: SearchFilter,
        searchNovelUseCase: SearchNovelUseCase,
        logger: Logger? = nil,
        analyticsTracker: AnalyticsTracker? = nil,
        onRoute: @escaping (DetailSearchResultRoute) -> Void
    ) -> some View {
        DetailSearchResultView(
            viewModel: DetailSearchResultViewModel(
                filter: filter,
                searchNovelUseCase: searchNovelUseCase,
                logger: logger,
                analyticsTracker: analyticsTracker
            ),
            onRoute: onRoute
        )
    }
}
