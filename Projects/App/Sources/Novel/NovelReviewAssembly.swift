//
//  NovelReviewAssembly.swift
//  WSS-iOS
//
//  Created by Guryss on 8/20/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import NovelReviewDomain
import NovelReviewFeature
// 키워드 탐색 시트(KeywordSearchSheetBuilder) 조립 — NovelReviewFeature는 KeywordFeature를 모른다.
import KeywordFeature

/// 작품 평가(`NovelReviewFeatureFactory`) 조립 — 홈/피드/서재 세 탭의 작품 상세가 전부 같은 방식으로
/// push해서(#197) 공용으로 뽑았다(`NovelDetailAssembly`/`FeedDetailAssembly`/`SearchAssembly`와 같은
/// 이유). `title`은 호출자가 `NovelDetailFeature`의 `onReviewTapped(NovelInformation, ReadingStatus)`
/// 콜백에서 받은 `NovelInformation.novel.title`을 그대로 넘긴다(진입 이전 화면이 이미 아는 값이라
/// `NovelReviewFeatureFactory`가 새로 조회하지 않는다).
@MainActor
enum NovelReviewAssembly {
    /// - Parameter onSaved: 저장 **성공**으로 닫힐 때 dismiss 직전 발화(#236) — 호출자(탭 Root)가
    ///   크로스스크린 피드백 채널로 "평가 완료" 토스트를 복귀 화면 위에 띄운다.
    static func makeView(
        novelID: NovelID,
        title: String,
        status: ReadingStatus,
        dependencies: AppDependencies,
        onAuthenticationRequired: @escaping () -> Void,
        onSaved: @escaping () -> Void
    ) -> some View {
        NovelReviewFeatureFactory.makeView(
            novelID: novelID,
            title: title,
            status: status,
            loadUseCase: DefaultLoadNovelReviewDraftUseCase(repository: dependencies.novelReviewRepository),
            saveUseCase: DefaultSaveNovelReviewUseCase(repository: dependencies.novelReviewRepository),
            appReviewUseCase: DefaultAppReviewRequestUseCase(repository: dependencies.appReviewRequestRepository),
            logger: dependencies.logger,
            onAuthenticationRequired: onAuthenticationRequired,
            onSaved: onSaved,
            keywordSearchSheet: keywordSearchSheet(dependencies: dependencies)
        )
    }

    /// 키워드 탐색 시트 콘텐츠 — `SearchKeywordView`(App이 조립)는 자체 액션바가 없어 그대로 반환한 뒤
    /// `NovelReviewView`가 하단 "완료" 버튼을 얹는다. `HomeRootView`의 상세탐색 키워드 탭 조립과 같은 UseCase.
    private static func keywordSearchSheet(dependencies: AppDependencies) -> KeywordSearchSheetBuilder {
        { initialKeywords, onSelectionChanged in
            AnyView(
                KeywordFeatureFactory.makeSearchKeywordView(
                    loadTotalKeywordsUseCase: DefaultFetchTotalKeywordsUseCase(keywordRepository: dependencies.keywordRepository),
                    searchKeywordsUseCase: DefaultSearchKeywordUseCase(keywordRepository: dependencies.keywordRepository),
                    initialSelectedKeywords: initialKeywords,
                    onSelectionChanged: onSelectionChanged,
                    logger: dependencies.logger
                )
            )
        }
    }
}
