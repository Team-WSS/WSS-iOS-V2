//
//  SearchAssembly.swift
//  WSS-iOS
//
//  Created by Guryss on 8/19/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import KeywordFeature
import NovelDomain
import RecommendationDomain
import SearchDomain
import SearchFeature

/// 일반 검색(`SearchFeatureFactory.makeNormalSearchView`) 조립 — 홈·서재 등 여러 탭이 같은 방식으로 push해서(#196) 공용으로
/// 뽑았다. `onNovelSelected`만 호출자별로 다르다(각 탭 Root가 자기 `Destination` enum에 맞게 push해야 해서).
///
/// ⚠️ **상세탐색 결과(`makeDetailSearchResultView`)는 `NormalSearchView`가 내부에서 직접 push하지 않고
/// 반드시 호출자(App)가 `onDetailSearchRequested` → 자기 `NavigationPath`로 push해야 한다** — Feature가
/// 로컬 `@State` + `.navigationDestination(item:)`으로 직접 push하던 예전 방식은, 그 화면 안에서 다시
/// `onNovelSelected`로 작품 상세를 열 때(App의 `path.append`) SwiftUI가 `path` 기준으로 스택을 다시 그려
/// **로컬로 push된 상세탐색 결과 화면이 통째로 사라지는 버그**가 있었다(#196 실측 — 작품 상세에서 뒤로가면
/// 상세탐색 결과가 아니라 그 이전 화면으로 바로 튕김). `NavigationPath` 기반 push와 `.navigationDestination
/// (item:)` 기반 push를 섞으면, `path`를 건드리는 순간 `path` 기준으로만 스택이 재계산되어 로컬로 얹힌
/// 화면이 스택에서 빠진다 — 상세탐색 결과처럼 "그 안에서 또 다른 화면으로 넘어가야 하는" 중간 화면은
/// **반드시 같은 `NavigationPath`에 태워야** 한다.
@MainActor
enum SearchAssembly {
    static func makeView(
        dependencies: AppDependencies,
        onNovelSelected: @escaping (NovelID) -> Void,
        onDetailSearchRequested: @escaping (SearchFilter) -> Void,
        onDetailSearchFilterRequested: @escaping (DetailSearchFilterTab) -> Void,
        initialQuery: String? = nil
    ) -> some View {
        SearchFeatureFactory.makeNormalSearchView(
            loadSosoPickUseCase: DefaultLoadSosoPickUseCase(recommendationRepository: dependencies.recommendationRepository),
            loadRecentSearchWordsUseCase: DefaultLoadRecentSearchWordsUseCase(recentSearchRepository: dependencies.searchRepository),
            removeRecentSearchWordUseCase: DefaultRemoveRecentSearchWordUseCase(recentSearchRepository: dependencies.searchRepository),
            clearRecentSearchWordsUseCase: DefaultClearRecentSearchWordsUseCase(recentSearchRepository: dependencies.searchRepository),
            searchAutoCompletionWordsUseCase: DefaultSearchAutoCompletionWordsUseCase(
                searchAutoCompletionRepository: dependencies.searchRepository
            ),
            searchNovelUseCase: DefaultSearchNovelUseCase(searchNovelRepository: dependencies.searchRepository),
            loadPopularKeywordsUseCase: DefaultLoadPopularKeywordsUseCase(keywordRepository: dependencies.keywordRepository),
            logger: dependencies.logger,
            initialQuery: initialQuery,
            onNovelSelected: onNovelSelected,
            onDetailSearchRequested: onDetailSearchRequested,
            onDetailSearchFilterRequested: onDetailSearchFilterRequested
        )
    }

    /// 상세탐색 필터 화면 조립(#236에서 `HomeRootView` 로컬 조립을 승격) — 홈 배너뿐 아니라 일반 검색의
    /// "더보기" 헤더(장르 → 정보 탭, 키워드 → 키워드 탭)로 3탭 어디서든 진입할 수 있어 공용으로 뽑았다.
    /// "키워드" 탭 콘텐츠는 `SearchFeature`가 `KeywordFeature`를 모르므로 여기서 조립해 값으로 건넨다
    /// (`KeywordTabContentBuilder`). 확정("작품 찾기") 후 pop/push 판단은 호출부(`onSearch`) 책임 —
    /// 각 Root는 자기 `Destination.detailSearch(filter)`를 push하고 필터 화면은 스택에 남긴다.
    static func makeDetailSearchFilterView(
        initialTab: DetailSearchFilterTab,
        dependencies: AppDependencies,
        onSearch: @escaping (SearchFilter) -> Void
    ) -> some View {
        SearchFeatureFactory.makeDetailSearchFilterView(
            initialTab: initialTab,
            keywordTabContent: { initialKeywords, onSelectionChanged in
                AnyView(
                    KeywordFeatureFactory.makeSearchKeywordView(
                        loadTotalKeywordsUseCase: DefaultFetchTotalKeywordsUseCase(keywordRepository: dependencies.keywordRepository),
                        searchKeywordsUseCase: DefaultSearchKeywordUseCase(keywordRepository: dependencies.keywordRepository),
                        initialSelectedKeywords: initialKeywords,
                        onSelectionChanged: onSelectionChanged,
                        logger: dependencies.logger
                    )
                )
            },
            onSearch: onSearch
        )
    }

    static func makeDetailSearchResultView(
        filter: SearchFilter,
        dependencies: AppDependencies,
        onNovelSelected: @escaping (NovelID) -> Void
    ) -> some View {
        SearchFeatureFactory.makeDetailSearchResultView(
            filter: filter,
            searchNovelUseCase: DefaultSearchNovelUseCase(searchNovelRepository: dependencies.searchRepository),
            logger: dependencies.logger,
            onNovelSelected: onNovelSelected
        )
    }
}
