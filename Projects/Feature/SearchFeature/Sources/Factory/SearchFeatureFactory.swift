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
/// (`Feature CLAUDE.md`의 Factory 규칙). `makeDetailSearchFilterView`는 #201부터 App(`SearchAssembly`)도
/// 실사용한다 — 홈 배너와 일반 검색의 "더보기" 헤더(#236)가 이 화면을 push한다(SearchFeature/CLAUDE.md
/// "필터 화면 진입·복귀" 참고). `makeDetailSearchResultView`도 App이 실사용하는 독립 진입점이다(#196부터,
/// "화면 간 이동" 참고).
public enum SearchFeatureFactory {

    /// - Parameters:
    ///   - onNovelSelected: 검색 결과·소소픽 작품 셀 탭 → 작품 상세 진입 콜백. 실제 화면 전환은
    ///     호출자(App 조정 계층)가 수행한다.
    ///   - onDetailSearchRequested: 장르 탭·인기 키워드 칩 탭 → 상세탐색 결과(`makeDetailSearchResultView`)
    ///     진입 콜백. 실제 화면 전환은 호출자(App 조정 계층)가 수행한다 — `NavigationPath` 혼용으로 화면이
    ///     안 쌓이는 문제 때문에 App이 직접 push해야 한다(`makeDetailSearchResultView` 참고).
    ///   - onDetailSearchFilterRequested: 장르·키워드 섹션 "더보기" 헤더 → 상세탐색 **필터 화면**
    ///     (`makeDetailSearchFilterView`) 진입 콜백(#236, V1 parity). 어느 탭으로 열지를 함께 넘긴다
    ///     (장르 더보기 → `.info`, 키워드 더보기 → `.keyword`).
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
        onDetailSearchRequested: @escaping (SearchFilter) -> Void = { _ in },
        onDetailSearchFilterRequested: @escaping (DetailSearchFilterTab) -> Void = { _ in }
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
            onDetailSearchRequested: onDetailSearchRequested,
            onDetailSearchFilterRequested: onDetailSearchFilterRequested
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
        onSearch: @escaping (SearchFilter) -> Void
    ) -> some View {
        DetailSearchFilterView(
            filter: filter,
            initialTab: initialTab,
            keywordTabContent: keywordTabContent,
            onSearch: onSearch
        )
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
