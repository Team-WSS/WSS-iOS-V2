//
//  NovelDetailFactory.swift
//  NovelDetailFeature
//
//  Created by YunhakLee on 7/9/26.
//  Copyright © 2026 kr.websoso.app. All rights reserved.
//

import SwiftUI

import BaseDomain
import NovelDomain
import FeedDomain
import Logger

/// 소설 상세 화면의 유일한 public 진입점. opaque 반환 → View/VM은 internal 유지.
public enum NovelDetailFactory {

    /// - Parameter onReviewTapped: 작품 평가 화면 진입 콜백. Feature 간 직접 의존 금지 —
    ///   실제 화면 전환(NovelReviewFactory 조립)은 호출자(App 조정 계층)가 수행한다.
    @MainActor
    public static func makeView(
        novelID: NovelID,
        loadNovelUseCase: LoadNovelUseCase,
        novelInterestUseCase: NovelInterestUseCase,
        loadNovelFeedsUseCase: LoadNovelFeedsUseCase,
        logger: Logger? = nil,
        onReviewTapped: @escaping (NovelInformation) -> Void
    ) -> some View {
        NovelDetailView(
            viewModel: NovelDetailViewModel(
                novelID: novelID,
                loadNovelUseCase: loadNovelUseCase,
                novelInterestUseCase: novelInterestUseCase,
                loadNovelFeedsUseCase: loadNovelFeedsUseCase,
                logger: logger
            ),
            onReviewTapped: onReviewTapped
        )
    }
}
