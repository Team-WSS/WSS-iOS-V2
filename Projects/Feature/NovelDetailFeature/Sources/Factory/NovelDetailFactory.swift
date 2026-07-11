//
//  NovelDetailFactory.swift
//  NovelDetailFeature
//
//  Created by YunhakLee on 7/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import FeedDomain
import NovelDomain
import Logger

/// 소설 상세 화면의 유일한 public 진입점. opaque 반환 → View/VM은 internal 유지.
public enum NovelDetailFactory {

    /// - Parameters:
    ///   - onReviewTapped: 작품 평가 화면 진입 콜백. Feature 간 직접 의존 금지 —
    ///     실제 화면 전환(NovelReviewFactory 조립)은 호출자(App 조정 계층)가 수행한다.
    ///     `ReadingStatus`는 평가 초안에 seed할 읽기 상태(상태바에서 탭한 상태 / 평가 있음의 칩·여백 탭은 현재 상태).
    ///   - onCreateFeedTapped: 피드 작성(CreateFeed) 진입 콜백 — "나도 한마디"·피드 탭 플로팅 버튼 공용.
    @MainActor
    public static func makeView(
        novelID: NovelID,
        loadNovelUseCase: LoadNovelUseCase,
        novelInterestUseCase: NovelInterestUseCase,
        loadNovelFeedsUseCase: LoadNovelFeedsUseCase,
        logger: Logger? = nil,
        onReviewTapped: @escaping (NovelInformation, ReadingStatus) -> Void,
        onCreateFeedTapped: @escaping () -> Void
    ) -> some View {
        NovelDetailView(
            viewModel: NovelDetailViewModel(
                novelID: novelID,
                loadNovelUseCase: loadNovelUseCase,
                novelInterestUseCase: novelInterestUseCase,
                loadNovelFeedsUseCase: loadNovelFeedsUseCase,
                logger: logger
            ),
            onReviewTapped: onReviewTapped,
            onCreateFeedTapped: onCreateFeedTapped
        )
    }
}
